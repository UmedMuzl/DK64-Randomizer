-- test_reachability.lua — smoke harness for the generated region graph + real state.lua.
--
-- Run from this directory:
--   lua test_reachability.lua

package.path = package.path .. ";./?.lua;./regions/?.lua"

local state = require("state")
local settings = require("settings_stub")

-- Generated region files reference these as globals.
_G.state = state
_G.settings = settings

local graph = require("graph")
state._event_lookup = function(name) return graph.is_event_active(name) end

local function set_count(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

local function show_reachable(label, verbose)
  graph.invalidate()
  local r = graph.reachable_regions()
  local e = graph.active_events()
  print(string.format("[%s] reachable=%d events=%d", label, set_count(r), set_count(e)))
  if verbose then
    local names = {}
    for n in pairs(r) do table.insert(names, n) end
    table.sort(names)
    for _, n in ipairs(names) do print("    " .. n) end
    if next(e) then
      print("  events:")
      local enames = {}
      for n in pairs(e) do table.insert(enames, n) end
      table.sort(enames)
      for _, n in ipairs(enames) do print("    " .. n) end
    end
  end
end

local function check(label, expected, actual)
  if expected == actual then
    print(string.format("  OK   %s = %s", label, tostring(actual)))
  else
    print(string.format("  FAIL %s expected=%s actual=%s", label, tostring(expected), tostring(actual)))
  end
end

print("=== Phase C: real state.lua against generated logic ===\n")

-- Empty state.
state.attrs = {}
settings.values = {}
settings.lists = {}
show_reachable("empty")

-- Grant DK + climbing + cannons + open_lobbies + fast_start + training barrels.
state.attrs = {
  donkey = true, coconut = true,
  climb = true, cannons = true,
  vine = true, dive = true, oranges = true, barrel = true,
  camera = true,
}
settings.values.open_lobbies = true
settings.values.fast_start_beginning_of_game = true
show_reachable("DK + basics + open_lobbies + fast_start")

-- Add Slam + chunky.
state.attrs.slam = 1
state.attrs.chunky = true
graph.invalidate()
check("JungleJapesMain reachable",            true,  graph.is_region_accessible("JungleJapesMain"))
-- Without phase/skew/JapesFreeKongOpenGates, can't reach JapesBeyondCoconutGate2 yet.
check("JapesBeyondCoconutGate2 reach (no phase)", false, graph.is_region_accessible("JapesBeyondCoconutGate2"))
check("Rambi event active (not in region yet)", false, graph.is_event_active("Rambi"))

-- Sanity: location-level.
graph.invalidate()
check("IslesClimbing accessible",      true,  graph.is_location_accessible("IslesClimbing"))
check("JapesChunkyBoulder accessible", true,  graph.is_location_accessible("JapesChunkyBoulder"))
check("Balloon006 (DK+coconut)",       true,  graph.is_location_accessible("Balloon006"))

-- Without coconut DK, Balloon006 should fail.
state.attrs.coconut = nil
graph.invalidate()
check("Balloon006 without coconut",    false, graph.is_location_accessible("Balloon006"))
state.attrs.coconut = true

-- Medal threshold via state.cb()
state.attrs.cb_JungleJapes_donkey = 50
settings.values.medal_cb_req_level = { 40 }
graph.invalidate()
check("JapesDonkeyMedal at 50/40",     true,  graph.is_location_accessible("JapesDonkeyMedal"))
state.attrs.cb_JungleJapes_donkey = 30
graph.invalidate()
check("JapesDonkeyMedal at 30/40",     false, graph.is_location_accessible("JapesDonkeyMedal"))

-- Glitch toggle: enable phasewalk + glitch logic, expect JapesBeyondPeanutGate via CanPhase.
state.attrs.cb_JungleJapes_donkey = 50  -- restore
settings.values.logic_type = "glitch"
settings.lists.glitches_selected = { "phase_walking" }
graph.invalidate()
check("CanPhase() with phase_walking", true, state.CanPhase())
check("JapesBeyondPeanutGate via phase",
      true, graph.is_region_accessible("JapesBeyondPeanutGate"))

-- Disable glitch logic; CanPhase should drop.
settings.values.logic_type = "glitchless"
graph.invalidate()
check("CanPhase() under glitchless",  false, state.CanPhase())

-- Tag-anywhere assumption: HasKong/IsKong both true for owned kong.
check("HasKong donkey",                true,  state.HasKong("donkey"))
check("IsKong donkey",                 true,  state.IsKong("donkey"))
check("HasKong diddy (not owned)",     false, state.HasKong("diddy"))

-- Vanilla JapesRambi switchsanity = donkey GunSwitch; with DK + coconut, evaluates true.
check("hasMoveSwitchsanity vanilla DK+coconut",
      true,  state.hasMoveSwitchsanity("JapesRambi", false))
-- Override to a chunky PadMove (gorillaGone) and confirm the type-dispatch works.
settings._switchsanity["JapesRambi"] = { kong = "chunky", switch_type = "PadMove" }
check("hasMoveSwitchsanity chunky PadMove (no gone)", false,
      state.hasMoveSwitchsanity("JapesRambi", false))
state.attrs.gone = true
check("hasMoveSwitchsanity chunky PadMove (with gone)", true,
      state.hasMoveSwitchsanity("JapesRambi", false))
-- Restore vanilla.
settings._switchsanity["JapesRambi"] = nil

-- With phasewalk on, we should be able to reach JapesBeyondCoconutGate2 and Rambi event fires.
settings.values.logic_type = "glitch"
settings.lists.glitches_selected = { "phase_walking" }
graph.invalidate()
check("JapesBeyondCoconutGate2 reach (phase)", true, graph.is_region_accessible("JapesBeyondCoconutGate2"))
check("Rambi event active (phase + DK+coconut)", true, graph.is_event_active("Rambi"))

print("\n=== summary ===")
show_reachable("final state")
