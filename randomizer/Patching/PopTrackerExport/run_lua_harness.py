"""Runs the Lua reachability smoke harness via lupa (embedded Lua 5.5).

Run with the spike venv:
    /tmp/lua_test_venv/bin/python3 -m randomizer.Patching.PopTrackerExport.run_lua_harness
"""
from __future__ import annotations

import sys
from pathlib import Path

import lupa

SPIKE_DIR = Path(__file__).resolve().parent / "_spike_output"


def main() -> int:
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    # Make `require` find files relative to the spike output directory.
    lua.execute(f"package.path = [[{SPIKE_DIR}/?.lua;{SPIKE_DIR}/?/init.lua]] .. ';' .. package.path")
    # Capture Lua print() to stdout (lupa already maps it to Python; this is just to confirm).
    script = (SPIKE_DIR / "test_reachability.lua").read_text()
    try:
        lua.execute(script)
    except lupa.LuaError as e:
        print("LUA ERROR:", e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
