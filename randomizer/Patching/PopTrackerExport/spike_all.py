"""Spike across every LogicFile + Shops.py. Reports per-file coverage."""
from __future__ import annotations

import ast
import sys
from collections import Counter
from pathlib import Path
from typing import List, Tuple

from .lambda_to_lua import LambdaTranspileError, TranspileContext, transpile_lambda

REPO_ROOT = Path(__file__).resolve().parents[3]
LOGIC_DIR = REPO_ROOT / "randomizer" / "LogicFiles"

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


def main() -> int:
    total_ok = 0
    total_err = 0
    grand_reasons: Counter = Counter()
    file_results: List[Tuple[str, int, int, int, Counter, List[Tuple[int, str, str]]]] = []
    for fname in LOGIC_FILES:
        path = LOGIC_DIR / fname
        ok, err, regions, reasons, sample_errs = _process_file(path)
        total_ok += ok
        total_err += err
        for k, v in reasons.items():
            grand_reasons[k] += v
        file_results.append((fname, ok, err, regions, reasons, sample_errs))

    print("\n=== Per-file coverage ===")
    print(f"{'file':28s} {'regions':>8s} {'ok':>6s} {'err':>6s} {'pct':>7s}")
    for fname, ok, err, regions, _, _ in file_results:
        total = ok + err
        pct = (100.0 * ok / total) if total else 100.0
        print(f"{fname:28s} {regions:8d} {ok:6d} {err:6d} {pct:6.1f}%")

    grand_total = total_ok + total_err
    pct = (100.0 * total_ok / grand_total) if grand_total else 100.0
    print(f"{'TOTAL':28s} {'':8s} {total_ok:6d} {total_err:6d} {pct:6.1f}%")

    if grand_reasons:
        print("\n=== Top error reasons (across all files) ===")
        for reason, n in grand_reasons.most_common(20):
            print(f"  {n:4d}  {reason}")

        print("\n=== Sample errors (first 5 per file with errors) ===")
        for fname, ok, err, _, _, sample_errs in file_results:
            if not sample_errs:
                continue
            print(f"\n--- {fname} ---")
            for lineno, name, msg in sample_errs[:5]:
                print(f"  line {lineno} [{name}]: {msg.splitlines()[0]}")
    return 0


def _process_file(path: Path) -> Tuple[int, int, int, Counter, List[Tuple[int, str, str]]]:
    src = path.read_text()
    tree = ast.parse(src, filename=str(path))
    ok = err = regions = 0
    reasons: Counter = Counter()
    sample_errs: List[Tuple[int, str, str]] = []

    for node in ast.walk(tree):
        if not (isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "LogicRegions" for t in node.targets)):
            continue
        if not isinstance(node.value, ast.Dict):
            continue
        for key, value in zip(node.value.keys, node.value.values):
            if not isinstance(key, ast.Attribute) or not isinstance(value, ast.Call):
                continue
            regions += 1
            args = list(value.args)
            if len(args) < 8:
                continue
            for list_node in (args[5], args[6], args[7]):
                if not isinstance(list_node, ast.List):
                    continue
                for elt in list_node.elts:
                    if not (isinstance(elt, ast.Call) and isinstance(elt.func, ast.Name) and elt.func.id in ("LocationLogic", "Event", "TransitionFront")):
                        continue
                    if len(elt.args) < 2 or not isinstance(elt.args[1], ast.Lambda):
                        continue
                    lam = elt.args[1]
                    src_text = ast.get_source_segment(src, lam) or ""
                    name = elt.args[0].attr if isinstance(elt.args[0], ast.Attribute) else ast.unparse(elt.args[0])
                    try:
                        transpile_lambda(lam, TranspileContext(filename=str(path), source=src_text))
                        ok += 1
                    except LambdaTranspileError as e:
                        err += 1
                        first = str(e).splitlines()[0]
                        reasons[first] += 1
                        if len(sample_errs) < 30:
                            sample_errs.append((lam.lineno, name, str(e)))
        break
    return ok, err, regions, reasons, sample_errs


if __name__ == "__main__":
    sys.exit(main())
