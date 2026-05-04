"""Runs the Lua reachability smoke harness via lupa (embedded Lua 5.5).

Run with the spike venv:
    /tmp/lua_test_venv/bin/python3 -m randomizer.Patching.PopTrackerExport.run_lua_harness
"""
from __future__ import annotations

import sys
from pathlib import Path

import lupa

EXPORT_DIR = Path(__file__).resolve().parent
RUNTIME_DIR = EXPORT_DIR / "runtime"
OUT_DIR = EXPORT_DIR / "out"


def main() -> int:
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    # `require("graph")` / `require("state")` resolve from runtime/; per-level region
    # files come from out/regions/. Both paths are added to Lua's search paths.
    paths = ";".join([
        f"{RUNTIME_DIR}/?.lua",
        f"{RUNTIME_DIR}/?/init.lua",
        f"{OUT_DIR}/?.lua",
        f"{OUT_DIR}/?/init.lua",
    ])
    lua.execute(f"package.path = [[{paths}]] .. ';' .. package.path")
    script = (RUNTIME_DIR / "test_reachability.lua").read_text()
    try:
        lua.execute(script)
    except lupa.LuaError as e:
        print("LUA ERROR:", e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
