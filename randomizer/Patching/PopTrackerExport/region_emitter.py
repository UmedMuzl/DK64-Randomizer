"""Region emitter — parses every randomizer/LogicFiles/*.py via AST and emits one Lua
file per level into the configured output directory.

Each emitted file contains an `M.regions` table keyed by region name, with sub-tables
for `locations`, `events`, and `exits`. Each entry has an `id` string and a `logic`
function that returns a boolean. Extra metadata (bonusBarrel, exitShuffleId,
isGlitchTransition, etc.) is attached as comment annotations and structured fields.

Run:
    python3 -m randomizer.Patching.PopTrackerExport.region_emitter [--out DIR]
"""
from __future__ import annotations

import argparse
import ast
import sys
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from .lambda_to_lua import LambdaTranspileError, TranspileContext, transpile_lambda

REPO_ROOT = Path(__file__).resolve().parents[3]
LOGIC_DIR = REPO_ROOT / "randomizer" / "LogicFiles"
DEFAULT_OUT = Path(__file__).resolve().parent / "_spike_output" / "regions"

LOGIC_FILES = [
    "AngryAztec.py",
    "CreepyCastle.py",
    "CrystalCaves.py",
    "DKIsles.py",
    "FranticFactory.py",
    "FungiForest.py",
    "GloomyGalleon.py",
    "HideoutHelm.py",
    "JungleJapes.py",
    "Shops.py",
]


@dataclass
class Entry:
    kind: str  # "location" | "event" | "exit"
    region: str
    name: str
    lineno: int
    lua_expr: Optional[str]
    error: Optional[str]
    extra: Dict[str, str] = field(default_factory=dict)


@dataclass
class RegionMeta:
    name: str
    display_name: str
    hint_region: str
    level: str
    tagbarrel: bool
    deathwarp: Optional[str]
    restart: Optional[str]


def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser(description="Emit per-level Lua region files from randomizer/LogicFiles.")
    parser.add_argument("--out", default=str(DEFAULT_OUT), help="Output directory for generated .lua files")
    args = parser.parse_args(argv)
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    grand_ok = grand_err = 0
    locations_index: List[Tuple[str, str, str]] = []  # (location_name, region_name, lua_expr)
    for fname in LOGIC_FILES:
        path = LOGIC_DIR / fname
        ok, err, locs = _emit_file(path, out_dir)
        grand_ok += ok
        grand_err += err
        locations_index.extend(locs)
        total = ok + err
        pct = (100.0 * ok / total) if total else 100.0
        print(f"  {fname:24s}  ok={ok:4d}  err={err:3d}  ({pct:5.1f}%)  locs={len(locs)}")

    grand = grand_ok + grand_err
    pct = (100.0 * grand_ok / grand) if grand else 100.0
    print(f"\nTOTAL  ok={grand_ok}  err={grand_err}  ({pct:.1f}%)  locations_indexed={len(locations_index)}")

    _emit_locations_index(out_dir, locations_index)
    print(f"  wrote {out_dir / 'locations_index.lua'}")
    return 1 if grand_err else 0


def _emit_file(src_path: Path, out_dir: Path) -> Tuple[int, int, List[Tuple[str, str, str]]]:
    src = src_path.read_text()
    tree = ast.parse(src, filename=str(src_path))
    regions: List[Tuple[RegionMeta, List[Entry]]] = []

    for node in ast.walk(tree):
        if not (isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "LogicRegions" for t in node.targets)):
            continue
        if not isinstance(node.value, ast.Dict):
            continue
        for key, value in zip(node.value.keys, node.value.values):
            if not (isinstance(key, ast.Attribute) and isinstance(value, ast.Call)):
                continue
            meta, entries = _parse_region(key.attr, value, src, str(src_path))
            regions.append((meta, entries))
        break

    out_path = out_dir / (src_path.stem + ".lua")
    ok = sum(1 for _, es in regions for e in es if e.lua_expr is not None)
    err = sum(1 for _, es in regions for e in es if e.error is not None)
    out_path.write_text(_render_lua(src_path.stem, regions))

    locs: List[Tuple[str, str, str]] = []
    for meta, entries in regions:
        for e in entries:
            if e.kind == "location" and e.lua_expr is not None:
                locs.append((e.name, meta.name, e.lua_expr))
    return ok, err, locs


def _emit_locations_index(out_dir: Path, locations: List[Tuple[str, str, str]]) -> None:
    """Emit a flat location-name → {region, logic} table."""
    seen: Dict[str, str] = {}
    lines: List[str] = [
        "-- AUTO-GENERATED — flat index of every Location to its containing region + access lambda.",
        "-- Note: a location can appear in multiple regions in randomizer logic (settings-dependent).",
        "-- We keep ALL definitions; the graph evaluator picks the first whose region is reachable.",
        "",
        "local M = {}",
        "M.locations = {}",
        "",
    ]
    for loc_name, region_name, lua_expr in locations:
        # Build M.locations[loc_name] as a list of {region, logic} entries.
        if loc_name not in seen:
            lines.append(f'M.locations["{loc_name}"] = {{')
            seen[loc_name] = "open"
        lines.append(f'  {{ region = "{region_name}", logic = function() return {lua_expr} end }},')
    # Close any open tables.
    # Simpler: rebuild grouped.
    grouped: Dict[str, List[Tuple[str, str]]] = {}
    for loc_name, region_name, lua_expr in locations:
        grouped.setdefault(loc_name, []).append((region_name, lua_expr))
    out_lines: List[str] = [
        "-- AUTO-GENERATED — flat index of every Location to its containing region(s) + access lambda(s).",
        "-- A location can legitimately appear in multiple regions when randomizer logic puts it",
        "-- in different places depending on settings. We keep all and OR them at evaluation time.",
        "",
        "local M = {}",
        "M.locations = {}",
        "",
    ]
    for loc_name, candidates in grouped.items():
        out_lines.append(f'M.locations["{loc_name}"] = {{')
        for region_name, lua_expr in candidates:
            out_lines.append(f'  {{ region = "{region_name}", logic = function() return {lua_expr} end }},')
        out_lines.append("}")
    out_lines.append("")
    out_lines.append("return M")
    (out_dir / "locations_index.lua").write_text("\n".join(out_lines))


def _parse_region(region_name: str, region_call: ast.Call, src: str, filename: str) -> Tuple[RegionMeta, List[Entry]]:
    """Region(name, hint, level, tagbarrel, deathwarp, locations, events, transitionFronts, restart=...)."""
    args = list(region_call.args)
    kwargs = {kw.arg: kw.value for kw in region_call.keywords}

    display_name = _str_const(args[0]) if len(args) >= 1 else region_name
    hint_region = _enum_member(args[1]) if len(args) >= 2 else "Unknown"
    level = _enum_member(args[2]) if len(args) >= 3 else "Unknown"
    tagbarrel = isinstance(args[3], ast.Constant) and bool(args[3].value) if len(args) >= 4 else False
    deathwarp = _format_simple(args[4]) if len(args) >= 5 else None
    restart_node = kwargs.get("restart")
    restart = _format_simple(restart_node) if restart_node is not None else None

    meta = RegionMeta(
        name=region_name,
        display_name=display_name or region_name,
        hint_region=hint_region or "Unknown",
        level=level or "Unknown",
        tagbarrel=tagbarrel,
        deathwarp=deathwarp,
        restart=restart,
    )

    entries: List[Entry] = []
    if len(args) >= 8:
        if isinstance(args[5], ast.List):
            for elt in args[5].elts:
                _maybe_entry(elt, region_name, "location", src, filename, entries)
        if isinstance(args[6], ast.List):
            for elt in args[6].elts:
                _maybe_entry(elt, region_name, "event", src, filename, entries)
        if isinstance(args[7], ast.List):
            for elt in args[7].elts:
                _maybe_entry(elt, region_name, "exit", src, filename, entries)
    return meta, entries


def _maybe_entry(call: ast.AST, region: str, kind: str, src: str, filename: str, out: List[Entry]) -> None:
    if not (isinstance(call, ast.Call) and isinstance(call.func, ast.Name) and call.func.id in ("LocationLogic", "Event", "TransitionFront")):
        return
    cls_name = call.func.id
    if len(call.args) < 2:
        out.append(Entry(kind, region, "<bad-args>", call.lineno, None, f"{cls_name}: <2 positional args"))
        return

    first = call.args[0]
    name = first.attr if isinstance(first, ast.Attribute) else ast.unparse(first)

    extra: Dict[str, str] = {}
    if cls_name == "LocationLogic" and len(call.args) >= 3:
        extra["bonusBarrel"] = _format_simple(call.args[2]) or "None"
    if cls_name == "TransitionFront":
        if len(call.args) >= 3:
            extra["exitShuffleId"] = _format_simple(call.args[2]) or "None"
        for kw in call.keywords:
            if kw.arg:
                extra[kw.arg] = _format_simple(kw.value) or ast.unparse(kw.value)

    lam = call.args[1]
    if not isinstance(lam, ast.Lambda):
        out.append(Entry(kind, region, name, call.lineno, None, f"{cls_name}.logic is not a lambda: {ast.unparse(lam)}", extra))
        return

    src_text = ast.get_source_segment(src, lam) or ""
    try:
        lua = transpile_lambda(lam, TranspileContext(filename=filename, source=src_text))
        out.append(Entry(kind, region, name, lam.lineno, lua, None, extra))
    except LambdaTranspileError as e:
        out.append(Entry(kind, region, name, lam.lineno, None, str(e), extra))


def _str_const(node: ast.AST) -> Optional[str]:
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        return node.value
    return None


def _enum_member(node: ast.AST) -> Optional[str]:
    if isinstance(node, ast.Attribute) and isinstance(node.value, ast.Name):
        return node.attr
    return None


def _format_simple(node: Optional[ast.AST]) -> Optional[str]:
    """Render a simple value for metadata (constants, enum members, None)."""
    if node is None:
        return None
    if isinstance(node, ast.Constant):
        v = node.value
        if v is None:
            return "None"
        if isinstance(v, bool):
            return "true" if v else "false"
        return str(v)
    if isinstance(node, ast.Attribute) and isinstance(node.value, ast.Name):
        return f"{node.value.id}.{node.attr}"
    if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub) and isinstance(node.operand, ast.Constant):
        return f"-{node.operand.value}"
    return None


def _render_lua(level_stem: str, regions: List[Tuple[RegionMeta, List[Entry]]]) -> str:
    lines: List[str] = [
        "-- AUTO-GENERATED — do not hand-edit.",
        f"-- Source: randomizer/LogicFiles/{level_stem}.py",
        "-- Regenerate via: python3 -m randomizer.Patching.PopTrackerExport.region_emitter",
        "",
        "local M = {}",
        "M.regions = {}",
        "",
    ]

    for meta, entries in regions:
        lines.append(f"-- region: {meta.name}  ({meta.display_name})")
        lines.append(f'M.regions["{meta.name}"] = {{')
        lines.append(f'  display_name = [[{meta.display_name}]],')
        lines.append(f'  hint_region  = "{meta.hint_region}",')
        lines.append(f'  level        = "{meta.level}",')
        lines.append(f'  tagbarrel    = {"true" if meta.tagbarrel else "false"},')
        if meta.deathwarp is not None:
            lines.append(f"  deathwarp    = {_lua_repr(meta.deathwarp)},")
        if meta.restart is not None:
            lines.append(f"  restart      = {_lua_repr(meta.restart)},")
        lines.append("  locations = {")
        for it in [x for x in entries if x.kind == "location"]:
            lines.append(_emit_entry(it))
        lines.append("  },")
        lines.append("  events = {")
        for it in [x for x in entries if x.kind == "event"]:
            lines.append(_emit_entry(it))
        lines.append("  },")
        lines.append("  exits = {")
        for it in [x for x in entries if x.kind == "exit"]:
            lines.append(_emit_entry(it))
        lines.append("  },")
        lines.append("}")
        lines.append("")
    lines.append("return M")
    return "\n".join(lines)


def _emit_entry(it: Entry) -> str:
    extras_parts: List[str] = []
    for k, v in it.extra.items():
        if v in (None, "None"):
            continue
        extras_parts.append(f'{k}={_lua_repr(v)}')
    extras = (", " + ", ".join(extras_parts)) if extras_parts else ""

    if it.error:
        first = it.error.splitlines()[0]
        return f'    -- ERROR [{it.name} @ line {it.lineno}] {first}'

    target_field = "id" if it.kind != "exit" else "dest"
    return f'    {{ {target_field} = "{it.name}", logic = function() return {it.lua_expr} end{extras} }},'


def _lua_repr(s: str) -> str:
    """Render a metadata value as Lua. Recognises 'true'/'false'/'None'/numbers; everything else becomes a quoted string."""
    if s == "true" or s == "false":
        return s
    if s == "None":
        return "nil"
    try:
        int(s)
        return s
    except ValueError:
        pass
    try:
        float(s)
        return s
    except ValueError:
        pass
    return f'"{s}"'


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
