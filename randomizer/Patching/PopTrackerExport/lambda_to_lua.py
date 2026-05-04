"""AST-based transpiler that converts the constrained Python lambda subset used in
randomizer/LogicFiles/*.py into equivalent Lua boolean expressions.

The output assumes a Lua runtime exposing:

  state.<attr>()           -- LogicVarHolder boolean attributes (donkey, coconut, ...)
  state.<method>(args)     -- LogicVarHolder methods (CanPhase, CanSlamSwitch, ...)
  state.event("<EventName>")  -- truthy if event is in l.Events
  state.special_loc("<LocationName>")  -- truthy if location in l.SpecialLocationsReached
  state.cb(level, kong)    -- l.ColoredBananas[level][kong]
  settings.<opt>()         -- l.settings.<opt> as a value
  settings.<opt>(...)      -- subscripted settings (medal_cb_req_level[0] -> settings.medal_cb_req_level(0))

Enum values like Levels.JungleJapes, Kongs.donkey, Switches.JapesDiddyCave become
string literals "JungleJapes", "donkey", "JapesDiddyCave".

This is intentionally a small surface. Anything outside it raises LambdaTranspileError
so the generator fails loudly rather than emitting wrong logic silently.
"""
from __future__ import annotations

import ast
from dataclasses import dataclass, field
from typing import List, Optional


class LambdaTranspileError(Exception):
    """Raised when a lambda body uses constructs the transpiler does not handle."""

    def __init__(self, message: str, source: str = "", filename: str = "", lineno: int = 0) -> None:
        suffix = ""
        if filename:
            suffix = f"\n  at {filename}:{lineno}"
        if source:
            suffix += f"\n  source: {source}"
        super().__init__(message + suffix)
        self.source = source
        self.filename = filename
        self.lineno = lineno


# Enum names whose members should be rendered as bare string literals.
# (Lua side keeps these as strings keyed into tables — much simpler than recreating enums.)
ENUM_AS_STRING = {
    "Kongs",
    "Levels",
    "Regions",
    "Switches",
    "Events",
    "Locations",
    "Maps",
    "Items",
    "Time",
    "Transitions",
    "MinigameType",
    "HintRegion",
    "Collectibles",
    "Types",
    "BarrierItems",
    "RemovedBarriersSelected",
    "FasterChecksSelected",
    "GlitchesSelected",
    "TricksSelected",
    "HardModeSelected",
    "HardBossesSelected",
    "MiscChangesSelected",
    "ProgressiveHintItem",
    "BananaportRando",
    "ShuffleLoadingZones",
    "TrainingBarrels",
    "ShockwaveStatus",
    "ClimbingStatus",
    "CannonStatus",
    "DamageAmount",
    "LogicType",
    "ActivateAllBananaports",
    "HelmSetting",
    "KongModels",
    "SlamRequirement",
    "WinConditionComplex",
    "SwitchType",
    "ShuffleDoors",
    "MinigameBarrels",
    "GalleonWaterSetting",
    "FungiTimeSetting",
    "CBRando",
}


@dataclass
class TranspileContext:
    """Carries filename/source so error messages point back to the offending lambda.

    `references`, when supplied by the caller, is populated as a side-effect with every
    attribute / method / setting / event / item / enum-member name encountered. This
    lets the generator cross-check against setting_map.py.
    """

    filename: str = ""
    source: str = ""
    # Names introduced by the lambda (e.g. the parameter name) — references to these
    # should not be rewritten as state.X.
    bound_names: List[str] = field(default_factory=list)
    references: Optional["AttrReferences"] = None


class AttrReferences:
    """Collects every name referenced inside transpiled lambdas, by category."""

    def __init__(self) -> None:
        self.state_attrs: set = set()      # l.<attr>           -> "donkey", "coconut", ...
        self.state_methods: set = set()    # l.<method>(...)    -> "CanPhase", "CanSlamSwitch", ...
        self.settings_attrs: set = set()   # l.settings.<opt>   -> "free_trade_items", ...
        self.settings_lists: set = set()   # l.settings.<list_opt> seen in `in` -> "glitches_selected", ...
        self.events: set = set()           # Events.X in l.Events
        self.special_locs: set = set()     # Locations.X in l.SpecialLocationsReached
        self.items: set = set()            # Items.X in ownedItems
        # Enum-member references (Class.Member) — to validate against the enum's value space.
        self.enum_members: dict = {}       # {enum_class: set(member_name, ...)}

    def record_enum(self, cls: str, member: str) -> None:
        self.enum_members.setdefault(cls, set()).add(member)

    def merge(self, other: "AttrReferences") -> None:
        self.state_attrs |= other.state_attrs
        self.state_methods |= other.state_methods
        self.settings_attrs |= other.settings_attrs
        self.settings_lists |= other.settings_lists
        self.events |= other.events
        self.special_locs |= other.special_locs
        self.items |= other.items
        for cls, members in other.enum_members.items():
            self.enum_members.setdefault(cls, set()).update(members)


def transpile_lambda(node: ast.Lambda, ctx: Optional[TranspileContext] = None) -> str:
    """Transpile a single ast.Lambda node's body to a Lua expression string."""
    if ctx is None:
        ctx = TranspileContext()
    if node.args.vararg or node.args.kwarg or node.args.kwonlyargs or node.args.defaults:
        raise LambdaTranspileError(
            "lambda has unsupported argument form (varargs / kwargs / defaults)",
            source=ctx.source,
            filename=ctx.filename,
            lineno=node.lineno,
        )
    bound = list(ctx.bound_names) + [a.arg for a in node.args.args]
    inner = TranspileContext(filename=ctx.filename, source=ctx.source, bound_names=bound, references=ctx.references)
    return _expr(node.body, inner)


def _expr(node: ast.AST, ctx: TranspileContext) -> str:
    method = _DISPATCH.get(type(node))
    if method is None:
        raise LambdaTranspileError(
            f"unsupported AST node {type(node).__name__}",
            source=ctx.source,
            filename=ctx.filename,
            lineno=getattr(node, "lineno", 0),
        )
    return method(node, ctx)


def _const(node: ast.Constant, ctx: TranspileContext) -> str:
    v = node.value
    if v is True:
        return "true"
    if v is False:
        return "false"
    if v is None:
        return "nil"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        # Use Lua's [[ ]] form to avoid escaping concerns; lambdas don't contain ]] strings.
        if "]]" in v:
            return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
        return f"[[{v}]]"
    raise LambdaTranspileError(
        f"unsupported constant of type {type(v).__name__}",
        source=ctx.source,
        filename=ctx.filename,
        lineno=node.lineno,
    )


def _name(node: ast.Name, ctx: TranspileContext) -> str:
    # Bare names that aren't bound parameters are usually module-level imports
    # (e.g. an enum class accessed without a member, or a module-level helper).
    # In well-formed LogicFile lambdas this should be rare.
    if node.id in ctx.bound_names:
        return node.id
    raise LambdaTranspileError(
        f"unsupported bare name reference: {node.id!r}",
        source=ctx.source,
        filename=ctx.filename,
        lineno=node.lineno,
    )


def _attribute(node: ast.Attribute, ctx: TranspileContext) -> str:
    # Cases:
    #   l.X                         -> state.X()              (boolean attr)
    #   l.settings.X                -> settings.X()
    #   l.Events                    -> state.events_table()   (only valid as RHS of `in`; handled there)
    #   l.SpecialLocationsReached   -> state.special_locs_table()
    #   l.ColoredBananas            -> handled via Subscript
    #   EnumName.Member             -> "Member"
    val = node.value

    # Enum member: Foo.Bar where Foo is in ENUM_AS_STRING.
    if isinstance(val, ast.Name) and val.id in ENUM_AS_STRING:
        if ctx.references is not None:
            ctx.references.record_enum(val.id, node.attr)
        return f'"{node.attr}"'

    # l.settings.<opt>  -> settings.<opt>()
    if (
        isinstance(val, ast.Attribute)
        and val.attr == "settings"
        and isinstance(val.value, ast.Name)
        and val.value.id in ctx.bound_names
    ):
        if ctx.references is not None:
            ctx.references.settings_attrs.add(node.attr)
        return f"settings.{node.attr}()"

    # l.<attr>
    if isinstance(val, ast.Name) and val.id in ctx.bound_names:
        # Tag-anywhere collapse: archipelago/Logic.py forces tag_anywhere on, so
        # `l.isdonkey` etc. always equal the corresponding ownership flag. Rewrite at
        # transpile time so state.lua doesn't need to maintain duplicate `is<kong>` helpers.
        ISX_ALIAS = {
            "isdonkey": "donkey",
            "isdiddy":  "diddy",
            "islanky":  "lanky",
            "istiny":   "tiny",
            "ischunky": "chunky",
        }
        if node.attr in ISX_ALIAS:
            base = ISX_ALIAS[node.attr]
            if ctx.references is not None:
                ctx.references.state_attrs.add(base)
            return f"state.{base}()"

        # Special-cased "container" attributes that only make sense in `in`/Subscript context.
        # If we get here, they're being read directly — not supported.
        if node.attr in ("Events", "SpecialLocationsReached", "ColoredBananas", "settings"):
            if node.attr == "settings":
                # Bare `l.settings` should always appear as part of a longer chain handled above.
                raise LambdaTranspileError(
                    "bare l.settings reference (expected l.settings.<option>)",
                    source=ctx.source,
                    filename=ctx.filename,
                    lineno=node.lineno,
                )
            raise LambdaTranspileError(
                f"l.{node.attr} can only be used in `in` membership or subscript context",
                source=ctx.source,
                filename=ctx.filename,
                lineno=node.lineno,
            )
        if ctx.references is not None:
            ctx.references.state_attrs.add(node.attr)
        return f"state.{node.attr}()"

    raise LambdaTranspileError(
        f"unsupported attribute access: {ast.unparse(node)}",
        source=ctx.source,
        filename=ctx.filename,
        lineno=node.lineno,
    )


def _call(node: ast.Call, ctx: TranspileContext) -> str:
    if node.keywords:
        raise LambdaTranspileError(
            "keyword arguments in calls are not supported",
            source=ctx.source,
            filename=ctx.filename,
            lineno=node.lineno,
        )
    args_lua = [_expr(a, ctx) for a in node.args]
    func = node.func

    # l.method(args) -> state.method(args)
    if (
        isinstance(func, ast.Attribute)
        and isinstance(func.value, ast.Name)
        and func.value.id in ctx.bound_names
    ):
        if ctx.references is not None:
            ctx.references.state_methods.add(func.attr)
        return f"state.{func.attr}({', '.join(args_lua)})"

    # l.settings.method(args)  (rare but possible) -> settings.method(args)
    if (
        isinstance(func, ast.Attribute)
        and isinstance(func.value, ast.Attribute)
        and func.value.attr == "settings"
        and isinstance(func.value.value, ast.Name)
        and func.value.value.id in ctx.bound_names
    ):
        if ctx.references is not None:
            ctx.references.settings_attrs.add(func.attr)
        return f"settings.{func.attr}({', '.join(args_lua)})"

    # Bare builtins: max(a,b), min(a,b), int(x), len(x)
    if isinstance(func, ast.Name):
        name = func.id
        if name == "max":
            return f"math.max({', '.join(args_lua)})"
        if name == "min":
            return f"math.min({', '.join(args_lua)})"
        if name == "int":
            if len(args_lua) != 1:
                raise LambdaTranspileError(
                    "int() takes exactly one argument",
                    source=ctx.source,
                    filename=ctx.filename,
                    lineno=node.lineno,
                )
            return f"math.floor({args_lua[0]})"
        if name == "len":
            if len(args_lua) != 1:
                raise LambdaTranspileError(
                    "len() takes exactly one argument",
                    source=ctx.source,
                    filename=ctx.filename,
                    lineno=node.lineno,
                )
            return f"(#({args_lua[0]}))"
        if name == "abs":
            return f"math.abs({', '.join(args_lua)})"

    raise LambdaTranspileError(
        f"unsupported call form: {ast.unparse(node)}",
        source=ctx.source,
        filename=ctx.filename,
        lineno=node.lineno,
    )


def _boolop(node: ast.BoolOp, ctx: TranspileContext) -> str:
    op = " and " if isinstance(node.op, ast.And) else " or "
    parts = [_expr(v, ctx) for v in node.values]
    return "(" + op.join(parts) + ")"


def _unaryop(node: ast.UnaryOp, ctx: TranspileContext) -> str:
    if isinstance(node.op, ast.Not):
        return f"(not {_expr(node.operand, ctx)})"
    if isinstance(node.op, ast.USub):
        return f"(-{_expr(node.operand, ctx)})"
    if isinstance(node.op, ast.UAdd):
        return _expr(node.operand, ctx)
    raise LambdaTranspileError(
        f"unsupported unary op {type(node.op).__name__}",
        source=ctx.source,
        filename=ctx.filename,
        lineno=node.lineno,
    )


_CMP_OPS = {
    ast.Eq: "==",
    ast.NotEq: "~=",
    ast.Lt: "<",
    ast.LtE: "<=",
    ast.Gt: ">",
    ast.GtE: ">=",
}


def _compare(node: ast.Compare, ctx: TranspileContext) -> str:
    # `In` membership: handle containers `l.Events`, `l.SpecialLocationsReached`, `ownedItems`.
    if len(node.ops) == 1 and isinstance(node.ops[0], (ast.In, ast.NotIn)):
        right = node.comparators[0]
        in_lua = _membership(node.left, right, ctx)
        if isinstance(node.ops[0], ast.NotIn):
            return f"(not {in_lua})"
        return in_lua

    # Chained comparisons get rewritten as ANDed pair-wise comparisons.
    parts: List[str] = []
    operands = [node.left] + list(node.comparators)
    for i, op in enumerate(node.ops):
        op_t = type(op)
        if op_t not in _CMP_OPS:
            raise LambdaTranspileError(
                f"unsupported comparison op {op_t.__name__}",
                source=ctx.source,
                filename=ctx.filename,
                lineno=node.lineno,
            )
        l = _expr(operands[i], ctx)
        r = _expr(operands[i + 1], ctx)
        parts.append(f"({l} {_CMP_OPS[op_t]} {r})")
    if len(parts) == 1:
        return parts[0]
    return "(" + " and ".join(parts) + ")"


def _membership(left: ast.AST, right: ast.AST, ctx: TranspileContext) -> str:
    """Render `left in right` for the supported container forms."""
    # `value in (A, B, C)` — tuple/list literal of enum members.
    # Render as `(value == A or value == B or value == C)`.
    if isinstance(right, (ast.Tuple, ast.List, ast.Set)):
        left_lua = _expr(left, ctx)
        parts = [f"({left_lua} == {_expr(elt, ctx)})" for elt in right.elts]
        return "(" + " or ".join(parts) + ")"

    # l.Events
    if (
        isinstance(right, ast.Attribute)
        and isinstance(right.value, ast.Name)
        and right.value.id in ctx.bound_names
        and right.attr == "Events"
    ):
        # left should be Events.Foo
        if (
            isinstance(left, ast.Attribute)
            and isinstance(left.value, ast.Name)
            and left.value.id == "Events"
        ):
            if ctx.references is not None:
                ctx.references.events.add(left.attr)
            return f'state.event("{left.attr}")'
        # Fall through: arbitrary expression as event name
        return f"state.event({_expr(left, ctx)})"

    # l.SpecialLocationsReached
    if (
        isinstance(right, ast.Attribute)
        and isinstance(right.value, ast.Name)
        and right.value.id in ctx.bound_names
        and right.attr == "SpecialLocationsReached"
    ):
        if (
            isinstance(left, ast.Attribute)
            and isinstance(left.value, ast.Name)
            and left.value.id == "Locations"
        ):
            if ctx.references is not None:
                ctx.references.special_locs.add(left.attr)
            return f'state.special_loc("{left.attr}")'
        return f"state.special_loc({_expr(left, ctx)})"

    # ownedItems (used in helper-method bodies, not LocationLogic lambdas, but defensible)
    if isinstance(right, ast.Name) and right.id == "ownedItems":
        if (
            isinstance(left, ast.Attribute)
            and isinstance(left.value, ast.Name)
            and left.value.id == "Items"
        ):
            if ctx.references is not None:
                ctx.references.items.add(left.attr)
            return f'state.has_item("{left.attr}")'
        return f"state.has_item({_expr(left, ctx)})"

    # l.settings.<list_opt>  (e.g. `LogicType.glitch in l.settings.glitches_selected`)
    if (
        isinstance(right, ast.Attribute)
        and isinstance(right.value, ast.Attribute)
        and right.value.attr == "settings"
        and isinstance(right.value.value, ast.Name)
        and right.value.value.id in ctx.bound_names
    ):
        if ctx.references is not None:
            ctx.references.settings_lists.add(right.attr)
        # Render as settings.<opt>_contains("Member")
        if isinstance(left, ast.Attribute) and isinstance(left.value, ast.Name):
            return f'settings.{right.attr}_contains("{left.attr}")'
        return f"settings.{right.attr}_contains({_expr(left, ctx)})"

    raise LambdaTranspileError(
        f"unsupported `in` container: {ast.unparse(right)}",
        source=ctx.source,
        filename=ctx.filename,
        lineno=getattr(right, "lineno", 0),
    )


def _subscript(node: ast.Subscript, ctx: TranspileContext) -> str:
    # l.ColoredBananas[level][kong] -> state.cb(level, kong)
    val = node.value
    # Two-level: l.ColoredBananas[lvl][kong]
    if (
        isinstance(val, ast.Subscript)
        and isinstance(val.value, ast.Attribute)
        and isinstance(val.value.value, ast.Name)
        and val.value.value.id in ctx.bound_names
        and val.value.attr == "ColoredBananas"
    ):
        lvl = _expr(val.slice, ctx)
        kong = _expr(node.slice, ctx)
        return f"state.cb({lvl}, {kong})"

    # l.settings.medal_cb_req_level[0] -> settings.medal_cb_req_level(0)
    if (
        isinstance(val, ast.Attribute)
        and isinstance(val.value, ast.Attribute)
        and val.value.attr == "settings"
        and isinstance(val.value.value, ast.Name)
        and val.value.value.id in ctx.bound_names
    ):
        if ctx.references is not None:
            ctx.references.settings_attrs.add(val.attr)
        idx = _expr(node.slice, ctx)
        return f"settings.{val.attr}({idx})"

    raise LambdaTranspileError(
        f"unsupported subscript: {ast.unparse(node)}",
        source=ctx.source,
        filename=ctx.filename,
        lineno=node.lineno,
    )


def _binop(node: ast.BinOp, ctx: TranspileContext) -> str:
    op_map = {
        ast.Add: "+",
        ast.Sub: "-",
        ast.Mult: "*",
        ast.Div: "/",
        ast.Mod: "%",
    }
    op_t = type(node.op)
    if op_t in op_map:
        return f"({_expr(node.left, ctx)} {op_map[op_t]} {_expr(node.right, ctx)})"
    if op_t is ast.RShift:
        # Lua 5.1 (PopTracker uses 5.3 with bit ops, but for portability use math.floor(... / 2^n))
        right = _expr(node.right, ctx)
        return f"math.floor({_expr(node.left, ctx)} / (2 ^ {right}))"
    if op_t is ast.LShift:
        right = _expr(node.right, ctx)
        return f"({_expr(node.left, ctx)} * (2 ^ {right}))"
    if op_t is ast.FloorDiv:
        return f"math.floor({_expr(node.left, ctx)} / {_expr(node.right, ctx)})"
    raise LambdaTranspileError(
        f"unsupported binary op {op_t.__name__}",
        source=ctx.source,
        filename=ctx.filename,
        lineno=node.lineno,
    )


def _ifexp(node: ast.IfExp, ctx: TranspileContext) -> str:
    test = _expr(node.test, ctx)
    body = _expr(node.body, ctx)
    orelse = _expr(node.orelse, ctx)
    # Safe Lua ternary only when body is never falsy. In LogicFile lambdas the operands
    # are always boolean-ish; this works for those. Wrap defensively in parens.
    return f"(({test}) and ({body}) or ({orelse}))"


def _tuple(node: ast.Tuple, ctx: TranspileContext) -> str:
    # Tuples appear in calls like state.something((1,2,3)); rare but render as a Lua table.
    return "{" + ", ".join(_expr(e, ctx) for e in node.elts) + "}"


_DISPATCH = {
    ast.Constant: _const,
    ast.Name: _name,
    ast.Attribute: _attribute,
    ast.Call: _call,
    ast.BoolOp: _boolop,
    ast.UnaryOp: _unaryop,
    ast.Compare: _compare,
    ast.Subscript: _subscript,
    ast.BinOp: _binop,
    ast.IfExp: _ifexp,
    ast.Tuple: _tuple,
}
