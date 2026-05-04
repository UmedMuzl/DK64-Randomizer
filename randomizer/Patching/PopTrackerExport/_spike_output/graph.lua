-- graph.lua — region/event reachability over the generated region graph.
--
-- Loads every per-level region table, then exposes:
--
--   M.is_region_accessible(region_name)
--   M.is_event_active(event_name)
--   M.is_location_accessible(location_name)
--   M.invalidate()        -- call when item state or settings change
--   M.reachable_regions() -- debugging: returns the set of reachable regions
--   M.active_events()     -- debugging: returns the set of active events
--
-- Algorithm: iterative fixpoint starting from START_REGION ("GameStart").
-- Each iteration: for every region currently reachable, evaluate its events
-- (mark new ones active) and exits (mark new destinations reachable). Repeat
-- until nothing new is added. Lambdas see the in-progress reachable/event
-- tables through `_G.event_set` / `state.event(name)`, so cycles between
-- events and regions converge naturally.

local M = {}

-- Per-spike: regions live next to this file under regions/<Level>.lua.
local LEVELS = {
  "AngryAztec", "CreepyCastle", "CrystalCaves", "DKIsles",
  "FranticFactory", "FungiForest", "GloomyGalleon", "HideoutHelm",
  "JungleJapes", "Shops",
}

local START_REGION = "GameStart"

M.regions = {}
for _, lvl in ipairs(LEVELS) do
  local mod = require("regions." .. lvl)
  for name, region in pairs(mod.regions) do
    if M.regions[name] then
      error("duplicate region definition: " .. name)
    end
    M.regions[name] = region
  end
end

M.locations = require("regions.locations_index").locations

-- These tables are exposed to lambdas via state.event() and (eventually) location lookups.
-- They are repopulated by compute() each time the cache is invalidated.
local _reachable = nil
local _events = nil

-- The state module reads from these — see state stub.
M._reachable = function() return _reachable end
M._events = function() return _events end

local function compute()
  local reachable = { [START_REGION] = true }
  local events = {}

  -- Make these visible to the state module's event() helper during the fixpoint pass.
  _reachable = reachable
  _events = events

  local changed = true
  local iterations = 0
  while changed do
    changed = false
    iterations = iterations + 1
    if iterations > 200 then
      error("graph reachability did not converge in 200 iterations")
    end
    for region_name, _ in pairs(reachable) do
      local region = M.regions[region_name]
      if region then
        for _, ev in ipairs(region.events or {}) do
          if not events[ev.id] then
            local ok, val = pcall(ev.logic)
            if ok and val then
              events[ev.id] = true
              changed = true
            end
          end
        end
        for _, ex in ipairs(region.exits or {}) do
          if not reachable[ex.dest] then
            local ok, val = pcall(ex.logic)
            if ok and val then
              reachable[ex.dest] = true
              changed = true
            end
          end
        end
      end
    end
  end

  _reachable = reachable
  _events = events
end

local function ensure() if _reachable == nil then compute() end end

function M.is_region_accessible(name)
  ensure()
  return _reachable[name] == true
end

function M.is_event_active(name)
  ensure()
  return _events[name] == true
end

function M.is_location_accessible(loc_name)
  ensure()
  local candidates = M.locations[loc_name]
  if not candidates then return false end
  for _, c in ipairs(candidates) do
    if _reachable[c.region] then
      local ok, val = pcall(c.logic)
      if ok and val then return true end
    end
  end
  return false
end

function M.invalidate()
  _reachable = nil
  _events = nil
end

function M.reachable_regions() ensure(); return _reachable end
function M.active_events() ensure(); return _events end

return M
