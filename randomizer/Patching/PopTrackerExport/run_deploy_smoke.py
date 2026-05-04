"""Smoke-test the deployed dk64pt copy: load it the way PopTracker would (via the
deployed init.lua) and run sanity assertions against the deployed graph.

Run:
    /tmp/lua_test_venv/bin/python3 -m randomizer.Patching.PopTrackerExport.run_deploy_smoke \\
        --dk64pt /home/umed/Documents/GitHub/dk64pt
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import lupa


def main(argv: list) -> int:
    parser = argparse.ArgumentParser(description="Smoke-test a dk64pt deploy.")
    parser.add_argument("--dk64pt", required=True)
    args = parser.parse_args(argv)
    pack_root = Path(args.dk64pt).resolve()
    target = pack_root / "scripts" / "logic" / "generated"
    if not target.exists():
        print(f"ERROR: deploy target {target} missing — run deploy.py first.", file=sys.stderr)
        return 2

    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    paths = ";".join([f"{target}/?.lua", f"{target}/regions/?.lua"])
    lua.execute(f"package.path = [[{paths}]] .. ';' .. package.path")

    init_lua = (target / "init.lua").read_text()
    # init.lua mutates package.path with a relative path that doesn't apply to our test cwd.
    safe_init = "\n".join(line for line in init_lua.splitlines() if "scripts/logic/generated" not in line)
    lua.execute(safe_init)

    print(f"Smoke-testing deploy at {target}\n")
    failures = 0

    def assert_lua(label, expected, snippet):
        nonlocal failures
        actual = lua.eval(snippet)
        marker = "OK  " if expected == actual else "FAIL"
        print(f"  {marker} {label:60s} -> {actual}")
        if expected != actual:
            failures += 1

    # State setup is done entirely in Lua to avoid lupa↔metatable interactions.
    lua.execute("""
state.attrs = {
  donkey = true, coconut = true,
  climb = true, cannons = true,
  vine = true, dive = true, oranges = true, barrel = true,
  camera = true,
  slam = 1, chunky = true,
}
settings.values = { open_lobbies = true, fast_start_beginning_of_game = true }
settings.lists = {}
graph.invalidate()
""")
    assert_lua("graph.is_region_accessible('JungleJapesMain')",            True,
               "graph.is_region_accessible('JungleJapesMain')")
    assert_lua("graph.is_region_accessible('JapesBeyondCoconutGate2') (no phase)", False,
               "graph.is_region_accessible('JapesBeyondCoconutGate2')")
    assert_lua("graph.is_location_accessible('Balloon006') (DK+coconut)", True,
               "graph.is_location_accessible('Balloon006')")
    assert_lua("loc('JapesChunkyBoulder')",                                True,
               "loc('JapesChunkyBoulder')")

    # Medal threshold via cb count + medal_cb_req_level.
    lua.execute("""
state.attrs.cb_JungleJapes_donkey = 50
settings.values.medal_cb_req_level = { 40 }
graph.invalidate()
""")
    assert_lua("loc('JapesDonkeyMedal') at 50/40",                         True,
               "loc('JapesDonkeyMedal')")

    lua.execute("state.attrs.cb_JungleJapes_donkey = 30; graph.invalidate()")
    assert_lua("loc('JapesDonkeyMedal') at 30/40",                         False,
               "loc('JapesDonkeyMedal')")

    # Toggle phase glitch logic — gate opens.
    lua.execute("""
state.attrs.cb_JungleJapes_donkey = 50
settings.values.logic_type = "glitch"
settings.lists = { glitches_selected = { "phase_walking" } }
graph.invalidate()
""")
    assert_lua("graph.is_region_accessible('JapesBeyondCoconutGate2') (phase)", True,
               "graph.is_region_accessible('JapesBeyondCoconutGate2')")
    assert_lua("graph.is_event_active('Rambi') (phase + DK+coconut)",      True,
               "graph.is_event_active('Rambi')")

    print()
    if failures == 0:
        print("OK: 8/8 deployed-bootstrap assertions passed.")
    else:
        print(f"FAIL: {failures} assertions failed against the deployed copy.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
