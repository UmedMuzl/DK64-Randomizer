-- settings_stub.lua — placeholder settings adapter for the spike harness.
-- Returns sensible defaults; harness can override via:
--   M.values[<opt>]     = scalar (returned by settings.<opt>())
--   M.values[<opt>]     = table  (returned element-wise by settings.<opt>(idx))
--   M.lists[<opt>]      = list of members for *_contains lookups
--   M.tables[<opt>]     = string-keyed table for keyed lookups (boss_kongs, boss_maps, ...)
--   M.switchsanity[<n>] = { kong = "donkey", switch_type = "PadMove" }
-- Anything unset falls back to DEFAULTS below.

local M = {}
M.values = {}
M.lists = {}
M.tables = {}
-- Stored under a private name so that settings.switchsanity(...) routes through the
-- metatable wrapper rather than returning this raw table.
M._switchsanity = {}

local DEFAULTS = {
  -- Toggle-ish settings.
  fast_start_beginning_of_game = false,
  free_trade_items = false,
  shuffle_shops = false,
  open_lobbies = false,
  auto_keys = false,
  crown_placement_rando = false,
  kasplat_rando = false,
  tns_location_rando = false,
  perma_death = false,
  wipe_file_on_death = false,
  wrinkly_location_rando = false,
  remove_wrinkly_puzzles = false,
  cannons_require_blast = false,
  disable_tag_barrels = false,
  cb_rando_enabled = false,
  crown_door_open = false,
  coin_door_open = false,

  -- Enum-like.
  shuffle_loading_zones = "none",
  fungi_time_internal = "day",
  galleon_water_internal = "lowered",
  bonus_barrels = "shuffled",
  bananaport_rando = "off",
  damage_amount = "default",
  chunky_phase_slam_req_internal = "green",
  logic_type = "glitchless",
  helm_setting = "default",
  diddy_freeing_kong = "any",
  lanky_freeing_kong = "any",
  tiny_freeing_kong = "any",
  chunky_freeing_kong = "any",

  -- Numeric.
  helm_phase_count = 5,
  mermaid_gb_pearls = 0,

  -- Tabular (Python-list) — read with settings.<opt>(idx).
  medal_cb_req_level = { 75, 75, 75, 75, 75, 75, 75 },
  level_order = { 0, 1, 2, 3, 4, 5, 6, 7 },

  -- Helm puzzle ordering: kong slot per phase.
  helm_donkey   = "donkey",
  helm_diddy    = "diddy",
  helm_lanky    = "lanky",
  helm_tiny     = "tiny",
  helm_chunky   = "chunky",
  helm_donkey_1 = false, helm_donkey_2 = false,
  helm_diddy_1  = false, helm_diddy_2  = false,
  helm_lanky_1  = false, helm_lanky_2  = false,
  helm_tiny_1   = false, helm_tiny_2   = false,
  helm_chunky_1 = false, helm_chunky_2 = false,

  -- K. Rool order.
  krool_donkey = false, krool_diddy = false, krool_lanky = false, krool_tiny = false, krool_chunky = false,
  krool_dillo1 = false, krool_dillo2 = false,
  krool_dog1 = false, krool_dog2 = false,
  krool_kutout = false, krool_madjack = false, krool_pufftoss = false,
}

-- Vanilla switchsanity mapping. Used by hasMoveSwitchsanity when the harness/PopTracker
-- hasn't surfaced randomized data. Sourced by inspection of randomizer/Lists/Switches.
-- Add entries here as the tests/regions exercise more switches.
local VANILLA_SWITCHSANITY = {
  JapesRambi          = { kong = "donkey", switch_type = "GunSwitch" },
  JapesDiddyCave      = { kong = "diddy",  switch_type = "GunSwitch" },
  JapesPainting       = { kong = "tiny",   switch_type = "GunSwitch" },
  JapesFeather        = { kong = "tiny",   switch_type = "GunSwitch" },
  AztecLlamaCoconut   = { kong = "donkey", switch_type = "GunSwitch" },
  AztecLlamaGrape     = { kong = "lanky",  switch_type = "GunSwitch" },
  AztecLlamaFeather   = { kong = "tiny",   switch_type = "GunSwitch" },
  GalleonLighthouse   = { kong = "donkey", switch_type = "GunSwitch" },
  GalleonShipwreck    = { kong = "any",    switch_type = "GunSwitch" },
  IslesHelmLobbyGone  = { kong = "chunky", switch_type = "PadMove" },
  JapesFreeKong       = { kong = "diddy",  switch_type = "GunSwitch" },
  AztecOKONGPuzzle    = { kong = "diddy",  switch_type = "MiscActivator" },
  AztecLlamaPuzzle    = { kong = "lanky",  switch_type = "InstrumentPad" },
  FactoryFreeKong     = { kong = "chunky", switch_type = "SlamSwitch" },
}

local SUFFIX = "_contains"

local function read_value(key, arg)
  local v = M.values[key]
  if v == nil then v = DEFAULTS[key] end
  if arg ~= nil and type(v) == "table" then
    -- Python 0-indexed -> Lua 1-indexed for numeric args; keyed tables left alone.
    if type(arg) == "number" then return v[arg + 1] end
    return v[arg]
  end
  return v
end

setmetatable(M, {
  __index = function(_, key)
    -- "<opt>_contains" -> list-membership probe.
    if #key > #SUFFIX and key:sub(-#SUFFIX) == SUFFIX then
      local opt = key:sub(1, -#SUFFIX - 1)
      return function(member)
        local lst = M.lists[opt]
        if not lst then return false end
        for _, v in ipairs(lst) do if v == member then return true end end
        return false
      end
    end

    -- "switchsanity" -> returns the per-switch table. Falls back to a small vanilla
    -- map when switchsanity isn't configured for the requested switch.
    if key == "switchsanity" then
      return function(name)
        local v = M._switchsanity[name]
        if v ~= nil then return v end
        return VANILLA_SWITCHSANITY[name]
      end
    end

    -- "boss_kongs" / "boss_maps" / other string-keyed lookups.
    if key == "boss_kongs" or key == "boss_maps" then
      return function(level)
        local t = M.tables[key]
        if t then return t[level] end
        return nil
      end
    end

    -- Default: settings.<opt>([arg]) returns the value, optionally indexing into a table.
    return function(arg) return read_value(key, arg) end
  end,
})

return M
