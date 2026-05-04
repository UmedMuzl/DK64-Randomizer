"""Spike: parse JungleJapes.py at AST level, transpile every lambda, and emit a Lua file.

Run:
    python -m randomizer.Patching.PopTrackerExport.spike_japes

Produces:
    randomizer/Patching/PopTrackerExport/_spike_output/japes.lua
    randomizer/Patching/PopTrackerExport/_spike_output/japes_coverage.txt
"""
from __future__ import annotations

import ast
import os
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple

from .lambda_to_lua import LambdaTranspileError, TranspileContext, transpile_lambda

REPO_ROOT = Path(__file__).resolve().parents[3]
JAPES_PATH = REPO_ROOT / "randomizer" / "LogicFiles" / "JungleJapes.py"
OUT_DIR = Path(__file__).resolve().parent / "_spike_output"


@dataclass
class TranspiledItem:
    kind: str  # "location" | "event" | "exit" | "deathwarp"
    region: str
    name: str  # location id, event name, or destination region
    lineno: int
    lua_expr: Optional[str]
    error: Optional[str]
    extra: dict  # bonusBarrel, exitShuffleId, isGlitchTransition, etc.


def main() -> int:
    src = JAPES_PATH.read_text()
    tree = ast.parse(src, filename=str(JAPES_PATH))

    items: List[TranspiledItem] = []
    region_count = 0

    for node in ast.walk(tree):
        # Find the LogicRegions = {...} dict assignment.
        if not (isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "LogicRegions" for t in node.targets)):
            continue
        if not isinstance(node.value, ast.Dict):
            continue
        for key, value in zip(node.value.keys, node.value.values):
            if not isinstance(key, ast.Attribute) or not isinstance(value, ast.Call):
                continue
            region_name = key.attr  # e.g. "JungleJapesStart"
            region_count += 1
            _process_region(region_name, value, src, items)
        break

    OUT_DIR.mkdir(exist_ok=True)
    _write_lua(items)
    coverage = _write_coverage(items, region_count)
    print(coverage)
    return 0


def _process_region(region_name: str, region_call: ast.Call, src: str, items: List[TranspiledItem]) -> None:
    """Region(name, hint, level, tagbarrel, deathwarp, locations, events, transitionFronts, restart=...)."""
    args = list(region_call.args)
    if len(args) < 8:
        items.append(TranspiledItem("error", region_name, "<region-shape>", region_call.lineno, None, f"Region call has only {len(args)} positional args", {}))
        return
    locations_node, events_node, exits_node = args[5], args[6], args[7]
    deathwarp_node = args[4]
    if not (isinstance(deathwarp_node, ast.Constant) and deathwarp_node.value is None):
        # Deathwarps are usually None or -1; record but don't error.
        items.append(TranspiledItem("deathwarp", region_name, ast.unparse(deathwarp_node), deathwarp_node.lineno, None, None, {}))

    if isinstance(locations_node, ast.List):
        for elt in locations_node.elts:
            _process_logic_call(elt, region_name, "location", src, items)
    if isinstance(events_node, ast.List):
        for elt in events_node.elts:
            _process_logic_call(elt, region_name, "event", src, items)
    if isinstance(exits_node, ast.List):
        for elt in exits_node.elts:
            _process_logic_call(elt, region_name, "exit", src, items)


def _process_logic_call(call: ast.AST, region_name: str, kind: str, src: str, items: List[TranspiledItem]) -> None:
    if not isinstance(call, ast.Call):
        return
    func = call.func
    cls_name = ""
    if isinstance(func, ast.Name):
        cls_name = func.id
    if cls_name not in ("LocationLogic", "Event", "TransitionFront"):
        return

    # First arg is name/dest; second arg is the lambda.
    if len(call.args) < 2:
        items.append(TranspiledItem(kind, region_name, "<bad-args>", call.lineno, None, f"{cls_name} has only {len(call.args)} args", {}))
        return
    first = call.args[0]
    name = ast.unparse(first) if not (isinstance(first, ast.Attribute) and isinstance(first.value, ast.Name)) else first.attr

    extra: dict = {}
    if cls_name == "LocationLogic" and len(call.args) >= 3:
        # bonusBarrel positional
        extra["bonusBarrel"] = ast.unparse(call.args[2])
    if cls_name == "TransitionFront":
        if len(call.args) >= 3:
            extra["exitShuffleId"] = ast.unparse(call.args[2])
        for kw in call.keywords:
            extra[kw.arg or "?"] = ast.unparse(kw.value)

    lam = call.args[1]
    if not isinstance(lam, ast.Lambda):
        items.append(TranspiledItem(kind, region_name, name, call.lineno, None, f"{cls_name}'s logic arg is not a lambda: {ast.unparse(lam)}", extra))
        return

    src_text = ast.get_source_segment(src, lam) or ""
    try:
        lua = transpile_lambda(lam, TranspileContext(filename=str(JAPES_PATH), source=src_text))
        items.append(TranspiledItem(kind, region_name, name, lam.lineno, lua, None, extra))
    except LambdaTranspileError as e:
        items.append(TranspiledItem(kind, region_name, name, lam.lineno, None, str(e), extra))


def _write_lua(items: List[TranspiledItem]) -> None:
    out = OUT_DIR / "japes.lua"
    lines: List[str] = [
        "-- AUTO-GENERATED SPIKE OUTPUT — do not hand-edit.",
        "-- Source: randomizer/LogicFiles/JungleJapes.py",
        "",
        "local M = {}",
        "M.regions = {}",
        "",
    ]

    by_region: dict = {}
    for it in items:
        by_region.setdefault(it.region, []).append(it)

    for region, region_items in by_region.items():
        lines.append(f"-- region: {region}")
        lines.append(f'M.regions["{region}"] = {{')
        lines.append("  locations = {")
        for it in [x for x in region_items if x.kind == "location"]:
            lines.append(_emit_lua_entry(it))
        lines.append("  },")
        lines.append("  events = {")
        for it in [x for x in region_items if x.kind == "event"]:
            lines.append(_emit_lua_entry(it))
        lines.append("  },")
        lines.append("  exits = {")
        for it in [x for x in region_items if x.kind == "exit"]:
            lines.append(_emit_lua_entry(it))
        lines.append("  },")
        lines.append("}")
        lines.append("")
    lines.append("return M")
    out.write_text("\n".join(lines))
    print(f"Wrote {out}")


def _emit_lua_entry(it: TranspiledItem) -> str:
    extras = ""
    if it.extra:
        kv = ", ".join(f"{k}={v!r}" for k, v in it.extra.items())
        extras = f"  -- {kv}"
    if it.error:
        return f'    -- ERROR [{it.name}] {it.error}{extras}'
    return f'    {{ id = "{it.name}", logic = function() return {it.lua_expr} end }},{extras}'


def _write_coverage(items: List[TranspiledItem], region_count: int) -> str:
    total = len(items)
    errors = [it for it in items if it.error]
    by_kind = Counter(it.kind for it in items)
    err_by_kind = Counter(it.kind for it in errors)
    err_reasons = Counter()
    for it in errors:
        first_line = (it.error or "").splitlines()[0]
        err_reasons[first_line] += 1

    lines: List[str] = []
    lines.append(f"Regions parsed: {region_count}")
    lines.append(f"Total entries:  {total}  (locations={by_kind['location']}, events={by_kind['event']}, exits={by_kind['exit']})")
    lines.append(f"Successful:     {total - len(errors)}  ({100 * (total - len(errors)) / total:.1f}%)")
    lines.append(f"Errors:         {len(errors)}  (locations={err_by_kind['location']}, events={err_by_kind['event']}, exits={err_by_kind['exit']})")
    lines.append("")
    lines.append("Top error reasons:")
    for reason, n in err_reasons.most_common(20):
        lines.append(f"  {n:3d}  {reason}")
    lines.append("")
    lines.append("First 30 errors with detail:")
    for it in errors[:30]:
        lines.append(f"  [{it.kind} {it.region}/{it.name} @ line {it.lineno}]")
        for ln in (it.error or "").splitlines():
            lines.append(f"      {ln}")

    text = "\n".join(lines)
    (OUT_DIR / "japes_coverage.txt").write_text(text)
    return text


if __name__ == "__main__":
    sys.exit(main())
