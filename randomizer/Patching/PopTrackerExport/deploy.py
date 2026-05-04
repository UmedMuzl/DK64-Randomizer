"""Mirror the generator's output + runtime into a dk64pt PopTracker pack.

Drops everything under <pack>/scripts/logic/generated/ — a self-contained directory
that does not collide with any existing dk64pt files. The pack only loads it after
manually editing scripts/logic/logic.lua (see the README this script writes).

Run:
    python3 -m randomizer.Patching.PopTrackerExport.deploy --dk64pt /path/to/dk64pt
    python3 -m randomizer.Patching.PopTrackerExport.deploy --dk64pt /path/to/dk64pt --dry-run

The deploy:
  1. Refreshes the generator output (re-emits regions and validates against setting_map).
  2. Copies runtime/state.lua and runtime/graph.lua to <pack>/scripts/logic/generated/.
  3. Copies out/regions/*.lua to <pack>/scripts/logic/generated/regions/.
  4. Writes a dk64pt-flavoured settings.lua adapter (defaults today, real wiring later).
  5. Writes <pack>/scripts/logic/generated/init.lua — single entry that loads everything.
  6. Writes <pack>/scripts/logic/generated/README.md — integration instructions.

Existing files are NEVER overwritten outside generated/. The pack remains functional
without wiring; only when scripts/logic/logic.lua opts in does the new logic activate.
"""
from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

EXPORT_DIR = Path(__file__).resolve().parent
RUNTIME_DIR = EXPORT_DIR / "runtime"
OUT_DIR = EXPORT_DIR / "out"


def main(argv: list) -> int:
    parser = argparse.ArgumentParser(description="Deploy generated logic into a dk64pt pack.")
    parser.add_argument("--dk64pt", required=True, help="Path to dk64pt repo root")
    parser.add_argument("--dry-run", action="store_true", help="Print actions without writing")
    parser.add_argument("--skip-emit", action="store_true", help="Don't re-emit regions; use whatever's in out/")
    args = parser.parse_args(argv)

    pack_root = Path(args.dk64pt).resolve()
    if not (pack_root / "manifest.json").exists():
        print(f"ERROR: {pack_root} doesn't look like a PopTracker pack (no manifest.json).", file=sys.stderr)
        return 2

    target_root = pack_root / "scripts" / "logic" / "generated"
    actions: list = []

    # 1. Refresh emission (writes to out/regions/).
    if not args.skip_emit:
        from . import region_emitter
        emit_rc = region_emitter.main([])
        if emit_rc != 0:
            print(f"ERROR: region_emitter exited with code {emit_rc}; aborting deploy.", file=sys.stderr)
            return emit_rc

    # 2. state.lua + graph.lua + dk64pt-flavoured settings.lua.
    actions.append(("copy", RUNTIME_DIR / "state.lua",      target_root / "state.lua"))
    actions.append(("copy", RUNTIME_DIR / "graph.lua",      target_root / "graph.lua"))
    actions.append(("write_settings_adapter", None,         target_root / "settings.lua"))

    # 3. regions/*.lua + locations_index.lua.
    for src in sorted(OUT_DIR.glob("regions/*.lua")):
        actions.append(("copy", src, target_root / "regions" / src.name))

    # 4. init.lua.
    actions.append(("write_init", None, target_root / "init.lua"))

    # 5. README.md.
    actions.append(("write_readme", None, target_root / "README.md"))

    # Execute (or dry-print).
    print(f"Target: {target_root}")
    print()
    for op, src, dst in actions:
        rel = dst.relative_to(pack_root)
        if op == "copy":
            print(f"  copy   {src.name:40s} -> {rel}")
            if not args.dry_run:
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
        elif op == "write_settings_adapter":
            print(f"  write  settings.lua adapter             -> {rel}")
            if not args.dry_run:
                dst.parent.mkdir(parents=True, exist_ok=True)
                dst.write_text(_settings_adapter_lua())
        elif op == "write_init":
            print(f"  write  init.lua bootstrap               -> {rel}")
            if not args.dry_run:
                dst.parent.mkdir(parents=True, exist_ok=True)
                dst.write_text(_init_lua())
        elif op == "write_readme":
            print(f"  write  README.md integration notes      -> {rel}")
            if not args.dry_run:
                dst.parent.mkdir(parents=True, exist_ok=True)
                dst.write_text(_readme_md())

    if args.dry_run:
        print("\n(dry run — no files written)")
    else:
        print("\nDeploy complete. See generated/README.md inside dk64pt for wiring steps.")
    return 0


def _settings_adapter_lua() -> str:
    return """-- settings.lua — dk64pt PopTracker settings adapter for the generated logic.
--
-- Reads from PopTracker provider codes when running live, falls back to defaults
-- when running in a test harness or before tracker codes have been wired up.
--
-- This is a TEMPORARY adapter; populating it with the full set of dk64pt setting
-- toggles is the first task for whoever integrates this further.

local M = {}
M.values = {}   -- harness override: scalar settings
M.lists  = {}   -- harness override: list-style settings (for *_contains())
M._switchsanity = {}

local function tracker_value(code)
  if _G.Tracker and type(_G.Tracker.ProviderCountForCode) == "function" then
    return _G.Tracker:ProviderCountForCode(code)
  end
  return nil
end

local function tracker_bool(code) local v = tracker_value(code); return v ~= nil and v > 0 end

-- Map randomizer settings to PopTracker provider codes. Add more as you wire toggles.
local TRACKER_BOOL = {
  open_lobbies                 = "openlobbies",
  free_trade_items             = nil,                    -- TODO: dk64pt code
  fast_start_beginning_of_game = nil,                    -- TODO
  shuffle_shops                = nil,                    -- TODO
  auto_keys                    = nil,                    -- TODO
  cannons_require_blast        = nil,                    -- TODO
  crown_placement_rando        = nil,                    -- TODO
  kasplat_rando                = nil,                    -- TODO
  tns_location_rando           = nil,                    -- TODO
  perma_death                  = nil,                    -- TODO
}

local DEFAULTS = {
  fast_start_beginning_of_game = false, free_trade_items = false, shuffle_shops = false,
  open_lobbies = false, auto_keys = false, crown_placement_rando = false,
  kasplat_rando = false, tns_location_rando = false, perma_death = false,
  wipe_file_on_death = false, wrinkly_location_rando = false, remove_wrinkly_puzzles = false,
  cannons_require_blast = false, disable_tag_barrels = false,
  shuffle_loading_zones = "none", fungi_time_internal = "day",
  galleon_water_internal = "lowered", bonus_barrels = "shuffled",
  bananaport_rando = "off", damage_amount = "default",
  chunky_phase_slam_req_internal = "green", logic_type = "glitchless",
  helm_setting = "default",
  diddy_freeing_kong = "any", lanky_freeing_kong = "any",
  tiny_freeing_kong = "any", chunky_freeing_kong = "any",
  helm_phase_count = 5, mermaid_gb_pearls = 0,
  medal_cb_req_level = { 75, 75, 75, 75, 75, 75, 75 },
  level_order = { 0, 1, 2, 3, 4, 5, 6, 7 },
  helm_donkey = "donkey", helm_diddy = "diddy", helm_lanky = "lanky",
  helm_tiny = "tiny", helm_chunky = "chunky",
  crown_door_open = false, coin_door_open = false,
}

local SUFFIX = "_contains"

local function read_value(key, arg)
  local code = TRACKER_BOOL[key]
  if code and (M.values[key] == nil) then
    return tracker_bool(code)
  end
  local v = M.values[key]
  if v == nil then v = DEFAULTS[key] end
  if arg ~= nil and type(v) == "table" then
    if type(arg) == "number" then return v[arg + 1] end
    return v[arg]
  end
  return v
end

setmetatable(M, {
  __index = function(_, key)
    if #key > #SUFFIX and key:sub(-#SUFFIX) == SUFFIX then
      local opt = key:sub(1, -#SUFFIX - 1)
      return function(member)
        local lst = M.lists[opt]
        if not lst then return false end
        for _, v in ipairs(lst) do if v == member then return true end end
        return false
      end
    end
    if key == "switchsanity" then
      return function(name) return M._switchsanity[name] end
    end
    if key == "boss_kongs" or key == "boss_maps" then
      return function(_level) return nil end  -- TODO: surface real boss data
    end
    return function(arg) return read_value(key, arg) end
  end,
})

return M
"""


def _init_lua() -> str:
    return """-- init.lua — single-entry bootstrap for the generated logic.
--
-- Usage from dk64pt/scripts/logic/logic.lua:
--   local generated = ScriptHost:LoadScript("scripts/logic/generated/init.lua")
--
-- After loading, four globals are available to the rest of the pack:
--   _G.state    — LogicVarHolder adapter (state.donkey(), state.CanPhase(), ...)
--   _G.settings — settings adapter
--   _G.graph    — region/event/location reachability
--   loc_<id>(name) — convenience predicate for location_<id> access rules

package.path = package.path
  .. ";scripts/logic/generated/?.lua"
  .. ";scripts/logic/generated/regions/?.lua"

_G.state    = require("state")
_G.settings = require("settings")
_G.graph    = require("graph")

state._event_lookup       = function(name) return graph.is_event_active(name) end
state._special_loc_lookup = function(_)    return false end

-- Convenience: $loc_<LocationId> in JSON access rules dispatches to graph.is_location_accessible.
function loc(name) return graph.is_location_accessible(name) end

return _G.graph
"""


def _readme_md() -> str:
    return """# Generated logic for dk64pt

This directory is auto-generated from DK64-Randomizer's logic.

**Do not hand-edit any file here.** Regenerate via:
```
python3 -m randomizer.Patching.PopTrackerExport.deploy --dk64pt <path-to-dk64pt>
```

## Layout
- `state.lua` — LogicVarHolder adapter (boolean attributes + ported helpers)
- `settings.lua` — settings adapter (PopTracker codes + defaults; expand as toggles get wired)
- `graph.lua` — region graph BFS + event fixpoint
- `regions/<Level>.lua` — per-level region tables (locations, events, exits)
- `regions/locations_index.lua` — flat location-name → region+logic index
- `init.lua` — single-entry bootstrap

## Wiring it into dk64pt

The generated logic is dormant until you call it. Add ONE line near the top of
[`scripts/logic/logic.lua`](../logic.lua):

```lua
ScriptHost:LoadScript("scripts/logic/generated/init.lua")
```

After that, three globals exist:
- `state.donkey()`, `state.CanPhase()`, ... — the LogicVarHolder API ported to Lua
- `settings.open_lobbies()`, ... — settings access
- `graph.is_region_accessible(R)`, `graph.is_event_active(E)`, `graph.is_location_accessible(L)`
- `loc(name)` — convenience function for location access rules

Cache invalidation: call `graph.invalidate()` whenever an item is received, a
toggle changes, or settings change. Wire this into `scripts/autotracking/archipelago.lua`.

## Using it from a location JSON

Replace a hand-written rule:
```json
"access_rules": ["$japesDKMedal"]
```
with:
```json
"access_rules": ["$loc|JapesDonkeyMedal"]
```
…where `loc` is the global function defined in `init.lua`. PopTracker treats
`$loc|Foo` as `loc("Foo")` (per its access-rule grammar — pipe separates the
function name from its single string argument).

## What's missing / next steps

1. Expand `settings.lua`'s `TRACKER_BOOL` table — most settings still return defaults.
2. Wire `graph.invalidate()` into the autotracking flow.
3. Replace existing tracker-only aggregators (medallogic.lua etc.) to call `state.X()`
   so they stop maintaining a parallel item-state model.
4. Migrate location JSONs gradually: any rule still using the legacy helpers
   (e.g. `$canEnterJapes`, `$japesDKMedal`) keeps working — `$loc|` is opt-in
   per location.

## Source of truth

Everything except `state.lua` is regenerated. `state.lua` is hand-translated
from `randomizer/Logic.py` with `@logic Logic.py:<line>` annotations on each
helper so divergence is reviewable.
"""


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
