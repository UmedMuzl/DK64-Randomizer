-- state.lua — runtime adapter that exposes LogicVarHolder's public surface to
-- the generated lambdas. Works under both PopTracker (reads Tracker item codes)
-- and the lupa test harness (reads from state.attrs).
--
-- Conventions:
--   state.<flag>()        -- boolean attribute (donkey, coconut, peanut, ...)
--   state.<helper>(args)  -- ported LogicVarHolder method (CanPhase, ...)
--   state.event(name)     -- looks up active event; populated by graph.lua
--   state.cb(level, kong) -- colored banana count for a (level, kong) pair
--
-- `settings` (a separate module) is expected to be a module-level global; the
-- generated region files reference `settings.<opt>()` and `settings.<opt>_contains(...)`.
--
-- Hand-translation note: methods are ported from randomizer/Logic.py. Each port
-- carries an `-- @logic Logic.py:<line>` annotation so divergence is reviewable.

local M = {}

-- =============================================================================
-- Backend: PopTracker vs test harness
-- =============================================================================

local has, count
if _G.Tracker and type(_G.Tracker.ProviderCountForCode) == "function" then
  -- PopTracker live mode.
  function count(code) return _G.Tracker:ProviderCountForCode(code) or 0 end
  function has(code, n) return count(code) >= (n or 1) end
else
  -- Test harness: state.attrs is a {code = number_or_bool} table set by the harness.
  M.attrs = {}
  function count(code)
    local v = M.attrs[code]
    if type(v) == "number" then return v end
    return v and 1 or 0
  end
  function has(code, n) return count(code) >= (n or 1) end
end
M._has = has
M._count = count

-- =============================================================================
-- Event / special-location lookup hooks (set by graph.lua during fixpoint)
-- =============================================================================

M._event_lookup = function(_) return false end
M._special_loc_lookup = function(_) return false end
function M.event(name) return M._event_lookup(name) end
function M.special_loc(name) return M._special_loc_lookup(name) end

-- =============================================================================
-- Kong + move + item attributes
-- @logic Logic.py:Reset/Update/__init__
-- =============================================================================

-- Kong ownership.
function M.donkey()  return has("donkey") end
function M.diddy()   return has("diddy") end
function M.lanky()   return has("lanky") end
function M.tiny()    return has("tiny") end
function M.chunky()  return has("chunky") end

-- NOTE: there is no separate "is<kong>" surface. The transpiler rewrites
-- `l.isdonkey`/`l.isdiddy`/... directly to `state.donkey()`/`state.diddy()`/... at
-- generation time, since archipelago/Logic.py forces tag_anywhere on. See
-- lambda_to_lua._attribute ISX_ALIAS.

-- Weapons (always require the owning kong).
function M.coconut()   return has("donkey") and has("coconut") end
function M.peanut()    return has("diddy")  and has("peanuts") end
function M.grape()     return has("lanky")  and has("grape")   end
function M.feather()   return has("tiny")   and has("feather") end
function M.pineapple() return has("chunky") and has("pineapple") end

-- Instruments.
function M.bongos()    return has("donkey") and has("bongos")   end
function M.guitar()    return has("diddy")  and has("guitar")   end
function M.trombone()  return has("lanky")  and has("trombone") end
function M.saxophone() return has("tiny")   and has("sax")      end
function M.triangle()  return has("chunky") and has("triangle") end

-- Active moves (kong-gated).
function M.blast()       return has("donkey") and has("blast")  end
function M.strongKong()  return has("donkey") and has("strong") end
function M.grab()        return has("donkey") and has("grab")   end
function M.charge()      return has("diddy")  and has("charge") end
function M.jetpack()     return has("diddy")  and has("rocket") end
function M.spring()      return has("diddy")  and has("spring") end
function M.handstand()   return has("lanky")  and has("orangstand") end
function M.balloon()     return has("lanky")  and has("balloon") end
function M.sprint()      return has("lanky")  and has("sprint") end
function M.mini()        return has("tiny")   and has("mini")   end
function M.twirl()       return has("tiny")   and has("twirl")  end
function M.monkeyport()  return has("tiny")   and has("port")   end
function M.hunkyChunky() return has("chunky") and has("big")    end
function M.punch()       return has("chunky") and has("punch")  end
function M.gorillaGone() return has("chunky") and has("gone")   end

-- Training-barrel-ish + shared abilities. In the tracker we always treat these
-- as on if the corresponding code is present (start_with_training_barrels = on).
function M.vines()         return has("vine")    end
function M.swim()          return has("dive")    end
function M.oranges()       return has("oranges") end
function M.barrels()       return has("barrel")  end
function M.climbing()      return has("climb")   end
function M.cannons()       return has("cannons") or has("cannon") end
function M.can_use_vines() return M.vines() end

-- Specials.
function M.camera()       return has("camera")    end
function M.shockwave()    return has("shockwave") end
function M.scope()        return has("sniper")    end
function M.homing()       return has("homing")    end
function M.nintendoCoin() return has("nintendo") end
function M.rarewareCoin() return has("rareware") end

-- Slam ladder. dk64pt represents Simian Slam progressively: 1 = base, 2 = super, 3 = super-duper.
local function slam_level()
  -- dk64pt uses a single "slam" code with progressive levels; some packs use
  -- separate greenslam/blueslam/redslam codes. We support both, picking the
  -- maximum effective tier.
  local n = count("slam")
  if has("redslam")  or n >= 3 then return 3 end
  if has("blueslam") or n >= 2 then return 2 end
  if has("greenslam") or n >= 1 then return 1 end
  return 0
end
function M.Slam()          return slam_level() >= 1 end
function M.superSlam()     return slam_level() >= 2 end
function M.superDuperSlam() return slam_level() >= 3 end
M.slam_level = slam_level

-- Keys.
function M.JapesKey()   return has("k1") end
function M.AztecKey()   return has("k2") end
function M.FactoryKey() return has("k3") end
function M.GalleonKey() return has("k4") end
function M.ForestKey() return has("k5") end
function M.CavesKey()   return has("k6") end
function M.CastleKey()  return has("k7") end
function M.HelmKey()    return has("k8") end

-- Misc collectible counts that lambdas occasionally read.
function M.Beans()    return count("bean")    end
function M.Pearls()   return count("pearl")   end
function M.Melons()   return 1  -- approximation; randomizer tracks current melons, tracker doesn't.
end
function M.Blueprints() return count("dkbp") + count("diddybp") + count("lankybp") + count("tinybp") + count("chunkybp") end

-- "kong" — current Kong as enum-value-int. With tag-anywhere on, treat as donkey by default.
function M.kong() return 0 end

-- Always-false assumption flags (matches archipelago/Logic.py's overrides).
function M.assumeAztecEntry()      return false end
function M.assumeKRoolAccess()     return false end
function M.assumeLevel4Entry()     return false end
function M.assumeLevel5Entry()     return false end
function M.assumeLevel7Entry()     return false end
function M.assumeLevel8Entry()     return false end
function M.assumeUpperIslesAccess() return false end

-- Region/area access flags driven by tracker toggles or NPC presence.
function M.snideAccess()  return has("snide")  end
function M.crankyAccess() return has("cranky") end
function M.candyAccess()  return has("candy")  end
function M.funkyAccess()  return has("funky")  end
function M.dayAccess()    return true end  -- conservative: assume reachable until proven otherwise
function M.nightAccess()  return true end
function M.allTrainingChecks() return M.vines() and M.swim() and M.oranges() and M.barrels() end

-- =============================================================================
-- Glitch / trick flags
-- @logic Logic.py:104-126
-- =============================================================================

local function glitch(name)
  if settings.logic_type() ~= "glitch" then return false end
  return settings.glitches_selected_contains(name)
end
local function trick(name)
  local lt = settings.logic_type()
  if lt ~= "glitch" and lt ~= "advanced_glitchless" then return false end
  return settings.tricks_selected_contains(name)
end

function M.phasewalk()           return glitch("phase_walking") end
function M.phaseswim()           return glitch("phase_swimming") end
function M.phasefall()           return glitch("phasefall") end
function M.moonkicks()           return glitch("moonkicks") end
function M.moontail()            return glitch("moontail") end
function M.ledgeclip()           return glitch("ledge_clips") end
function M.generalclips()        return glitch("general_clips") end
function M.lanky_blocker_skip()  return glitch("b_locker_skips") end
function M.dk_blocker_skip()     return glitch("b_locker_skips") end
function M.troff_skip()          return glitch("troff_n_scoff_skips") end
function M.spawn_snags()         return glitch("spawn_snags") end
function M.swim_through_shores() return glitch("swim_through_shores") end
function M.skew()                return glitch("skew") end
function M.tbs()
  if not glitch("tag_barrel_storage") then return false end
  return not settings.disable_tag_barrels()
end

function M.monkey_maneuvers()    return trick("monkey_maneuvers") end
function M.hard_shooting()       return trick("hard_shooting") end
function M.advanced_grenading()  return trick("advanced_grenading") end
function M.slope_resets()        return trick("slope_resets") end
function M.adv_orange_usage()    return trick("advanced_orange_usage") end

-- =============================================================================
-- Helper methods (ported from randomizer/Logic.py)
-- =============================================================================

-- @logic Logic.py:692
function M.CanPhaseswim() return M.phaseswim() and M.swim() end
-- @logic Logic.py:696
function M.CanSTS() return M.swim_through_shores() and M.swim() end
-- @logic Logic.py:700
function M.CanMoonkick()
  -- Krusha-model DK can't moonkick; until we model kong models, accept the glitch toggle.
  return M.moonkicks() and M.donkey()
end
-- @logic Logic.py:735
function M.CanMoontail() return M.moontail() and M.diddy() end
-- @logic Logic.py:704
function M.CanOStandTBSNoclip() return M.tbs() and M.handstand() and M.lanky() end
-- @logic Logic.py:739
function M.CanPhase() return M.phasewalk() or (M.phasefall() and M.chunky() and M.camera()) end
-- @logic Logic.py:708
function M.CanAccessRNDRoom() return M.CanPhase() or M.generalclips() or M.CanOStandTBSNoclip() end

-- @logic Logic.py:716
function M.CanSkew(swim, is_japes, kong_req)
  if is_japes == nil then is_japes = true end
  if kong_req == nil then kong_req = "any" end
  if swim then
    return M.skew() and M.swim() and M.HasGun(kong_req) and M.CanPhaseswim()
  end
  local satisfies_cannon_req = true
  if is_japes then satisfies_cannon_req = M.event("JapesAccessToCannon") end
  return M.skew() and M.oranges() and (settings.damage_amount() ~= "ohko") and satisfies_cannon_req
end

-- @logic Logic.py:712
function M.CanGetOnCannonGamePlatform()
  return M.event("WaterRaised") or (M.monkey_maneuvers() and (M.chunky() or M.lanky()))
end

-- @logic Logic.py:570
function M.CanSlamSwitch(_level, default_req)
  default_req = default_req or 1
  -- alter_switch_allocation overrides per-level; we don't model the per-level table yet,
  -- so fall through to the default requirement.
  if default_req <= 1 then return M.Slam() end
  if default_req == 2 then return M.superSlam() end
  if default_req == 3 then return M.superDuperSlam() end
  return true
end

-- @logic Logic.py:1223
function M.CanSlamChunkyPhaseSwitch()
  local stg = settings.chunky_phase_slam_req_internal()
  if stg == "blue" then return M.superSlam() end
  if stg == "red" then return M.superDuperSlam() end
  return M.Slam()
end

-- @logic Logic.py:614
function M.checkBarrier(name) return settings.removed_barriers_selected_contains(name) end
-- @logic Logic.py:610
function M.checkFastCheck(name) return settings.faster_checks_selected_contains(name) end
-- @logic Logic.py:589
function M.IsLavaWater() return settings.hard_mode_selected_contains("water_is_lava") end
-- @logic Logic.py:599
function M.IsHardFallDamage() return settings.hard_mode_selected_contains("reduced_fall_damage_threshold") end
-- @logic Logic.py:593
function M.HardBossesSettingEnabled(name) return settings.hard_bosses_selected_contains(name) end
-- @logic Logic.py:619
function M.galleonGatesStayOpen() return settings.misc_changes_selected_contains("remove_galleon_ship_timers") end
-- @logic Logic.py:627
function M.cabinBarrelMoved() return settings.misc_changes_selected_contains("move_spring_cabin_rocketbarrel") end

-- @logic Logic.py:790
function M.HasKong(kong)
  if kong == "donkey" then return M.donkey() end
  if kong == "diddy"  then return M.diddy()  end
  if kong == "lanky"  then return M.lanky()  end
  if kong == "tiny"   then return M.tiny()   end
  if kong == "chunky" then return M.chunky() end
  if kong == "any" then
    return M.donkey() or M.diddy() or M.lanky() or M.tiny() or M.chunky()
  end
  return false
end

-- @logic Logic.py:775
function M.IsKong(kong)
  if kong == "any" then return true end
  return M.HasKong(kong)
end

-- @logic Logic.py:805
function M.HasGun(kong)
  if kong == "any" then
    return M.coconut() or M.peanut() or M.grape() or M.feather() or M.pineapple()
  end
  if kong == "donkey" then return M.coconut() end
  if kong == "diddy"  then return M.peanut()  end
  if kong == "lanky"  then return M.grape()   end
  if kong == "tiny"   then return M.feather() end
  if kong == "chunky" then return M.pineapple() end
  return false
end

-- @logic Logic.py:821
function M.HasInstrument(kong)
  if kong == "any" then
    return M.bongos() or M.guitar() or M.trombone() or M.saxophone() or M.triangle()
  end
  if kong == "donkey" then return M.bongos() end
  if kong == "diddy"  then return M.guitar() end
  if kong == "lanky"  then return M.trombone() end
  if kong == "tiny"   then return M.saxophone() end
  if kong == "chunky" then return M.triangle() end
  return false
end

-- @logic Logic.py:649 — switchsanity gate
function M.hasMoveSwitchsanity(switch_name, kong_needs_current, level, default_slam_level)
  if kong_needs_current == nil then kong_needs_current = true end
  level = level or "JungleJapes"
  default_slam_level = default_slam_level or 0
  -- The randomizer reads settings.switchsanity_data[switch] which the tracker
  -- exposes as settings.switchsanity(<switch>) returning {kong=..., switch_type=...}.
  local data = settings.switchsanity(switch_name)
  if not data then return false end
  local kong_ok
  if kong_needs_current then kong_ok = M.IsKong(data.kong) else kong_ok = M.HasKong(data.kong) end
  local t = data.switch_type
  if t == "PadMove" then
    local pads = { donkey = M.blast(), diddy = M.spring(), lanky = M.balloon(), tiny = M.monkeyport(), chunky = M.gorillaGone() }
    return kong_ok and pads[data.kong] == true
  elseif t == "MiscActivator" then
    local misc = { donkey = M.grab(), diddy = M.charge(), lanky = false, tiny = false, chunky = false }
    return kong_ok and misc[data.kong] == true
  elseif t == "GunSwitch" then
    if data.kong == "any" then return M.HasGun("any") end
    return kong_ok and M.HasGun(data.kong)
  elseif t == "InstrumentPad" then
    if data.kong == "any" then return M.HasInstrument("any") end
    return kong_ok and M.HasInstrument(data.kong)
  elseif t == "SlamSwitch" then
    return kong_ok and M.CanSlamSwitch(level, default_slam_level)
  elseif t == "GunInstrumentCombo" then
    if data.kong == "any" then return M.HasGun("any") and M.HasInstrument("any") end
    return kong_ok and M.HasGun(data.kong) and M.HasInstrument(data.kong)
  elseif t == "PushableButton" or t == "PunchGrate" or t == "IceWall" or t == "Gong" then
    if data.kong == "diddy"  then return kong_ok and M.charge() end
    if data.kong == "chunky" then return kong_ok and M.punch()  end
  end
  return false
end

-- @logic Logic.py:1212
function M.isKrushaAdjacent(_kong)
  -- Without modeling per-Kong skin choice we conservatively assume default skins.
  return false
end

-- @logic Logic.py:931 — checks whether Diddy's cage can be opened.
-- Real impl reads spoiler.LocationList to short-circuit if item is NoItem; the
-- tracker doesn't have the spoiler, so we assume the cage has a real item.
function M.CanFreeDiddy() return M.hasMoveSwitchsanity("JapesFreeKong") end

-- @logic Logic.py:935 — picking up the caged item, which opens Japes' gates.
function M.CanOpenJapesGates()
  if not M.CanFreeDiddy() then return false end
  if M.IsKong(settings.diddy_freeing_kong()) then return true end
  if settings.free_trade_items() then return true end
  return false
end

-- @logic Logic.py:961
function M.CanFreeTiny()
  local kong = settings.tiny_freeing_kong()
  if kong == "diddy" or kong == "chunky" then return M.hasMoveSwitchsanity("AztecOKONGPuzzle") end
  if kong == "any" then return true end
  return M.IsKong(kong) or settings.free_trade_items()
end

-- @logic Logic.py:971
function M.CanLlamaSpit() return M.HasInstrument(settings.lanky_freeing_kong()) end

-- @logic Logic.py:975
function M.CanFreeLanky()
  return (M.swim() and M.hasMoveSwitchsanity("AztecLlamaPuzzle")) or M.CanPhase() or M.CanPhaseswim()
end

-- @logic Logic.py:982
function M.CanFreeChunky()
  return M.hasMoveSwitchsanity("FactoryFreeKong", true, "FranticFactory", 1)
end
function M.canOpenLlamaTemple()
  if not (M.checkBarrier("aztec_llama_switches") or M.event("LlamaFreed")) then return false end
  return M.hasMoveSwitchsanity("AztecLlamaCoconut")
      or M.hasMoveSwitchsanity("AztecLlamaGrape")
      or M.hasMoveSwitchsanity("AztecLlamaFeather")
end
function M.canTravelToMechFish()
  if settings.shuffle_loading_zones() ~= "all" or settings.bananaport_rando() == "off" then
    return M.swim()
  end
  local lh = M.checkBarrier("galleon_lighthouse_gate") or M.hasMoveSwitchsanity("GalleonLighthouse", false)
  local sy = M.checkBarrier("galleon_shipyard_area_gate") or M.hasMoveSwitchsanity("GalleonShipwreck", false)
  return M.swim() and lh and sy
end
function M.CanOpenForestLobbyGoneDoor()
  return M.gorillaGone() and M.chunky()
end

-- @logic Logic.py:603
function M.canAccessHelm()
  if M.HardBossesSettingEnabled("strict_helm_timer") then
    return M.snideAccess() and M.Blueprints() > (4 + 2 * (settings.helm_phase_count() or 0))
  end
  return M.snideAccess()
end

-- @logic Logic.py:1331
function M.CanBeatLankyPhase()
  if M.HardBossesSettingEnabled("beta_lanky_phase") then
    return M.lanky() and M.grape() and M.barrels()
  end
  return M.lanky() and M.trombone() and M.barrels()
end

-- @logic Logic.py:1232 — IsBossBeatable. Kept faithful to fill-time semantics
-- but skipping the level-order constraints (tracker doesn't fill).
function M.IsBossBeatable(level)
  local required_kong = settings.boss_kongs(level)
  local boss_map = settings.boss_maps(level)
  local has_moves = true
  if boss_map == "FactoryBoss" and required_kong == "tiny"
     and not M.HardBossesSettingEnabled("alternative_mad_jack_kongs") then
    has_moves = M.twirl() and M.Slam()
  elseif boss_map == "FactoryBoss" then
    has_moves = M.Slam()
  elseif boss_map == "FungiBoss" then
    has_moves = M.hunkyChunky() and M.barrels()
  elseif boss_map == "JapesBoss" or boss_map == "AztecBoss" or boss_map == "CavesBoss" then
    has_moves = M.barrels()
  elseif boss_map == "CastleBoss" then
    if M.IsLavaWater() then has_moves = M.Melons() >= 3 end
    has_moves = has_moves and M.cannons()
  elseif boss_map == "KroolDonkeyPhase" then
    has_moves = (M.blast() or not settings.cannons_require_blast()) and M.climbing()
  elseif boss_map == "KroolDiddyPhase" then
    has_moves = M.jetpack() and M.peanut()
  elseif boss_map == "KroolLankyPhase" then
    has_moves = M.CanBeatLankyPhase()
  elseif boss_map == "KroolTinyPhase" then
    has_moves = M.mini() and M.feather()
  elseif boss_map == "KroolChunkyPhase" then
    has_moves = M.punch() and M.CanSlamChunkyPhaseSwitch() and M.hunkyChunky() and M.gorillaGone()
  end
  return M.IsKong(required_kong) and has_moves
end

-- @logic Logic.py:1189
function M.IsBossReachable(level)
  -- Reachability of T&S is region-graph; here we just need the boss-blockade check.
  -- Tracker rebuilds reachability on item changes so a simple kong+key check suffices.
  return true
end

-- @logic Logic.py:1351 (simplified for tracker — entry gating handled by region graph)
function M.IsLevelEnterable(_level) return true end
-- @logic Logic.py:1282 (tracker isn't filling, so we don't enforce fill restrictions)
function M.HasFillRequirementsForLevel(_level) return true end
-- @logic Logic.py:919/925
function M.CrownDoorOpened() return settings.crown_door_open() end
function M.CoinDoorOpened()  return settings.coin_door_open() end
-- @logic Logic.py:1185
function M.IsKLumsyFree() return M.event("KLumsyTalkedTo") end
function M.isPriorHelmComplete(_kong) return false end

-- @logic Logic.py:1337
function M.HasEnoughRaceCoins(_map_id, _default_kong, _kong_mandatory)
  -- Race coin rando isn't surfaced in dk64pt yet; assume we have enough.
  return true
end

-- @logic Logic.py:1469/1476/1483 — tracker can't model these accurately yet.
function M.CanGetRarewareCoin() return M.HasGun("any") end
function M.CanGetRarewareGB()   return M.hunkyChunky() and M.chunky() end
function M.CanGetBlueprintReward(value)
  return M.Blueprints() >= (tonumber(value) or 0)
end

-- @logic Logic.py:1545
function M.CanSurviveFallDamage() return true end
-- @logic Logic.py:1100 (CanAccessKRool) — full evaluation is recursive and seed-dependent;
-- the region graph ultimately gates access, so this just checks the hard-coded blocker.
function M.CanAccessKRool() return M.JapesKey() and M.AztecKey() and M.FactoryKey() and M.GalleonKey() and M.ForestKey() and M.CavesKey() and M.CastleKey() and M.HelmKey() end
-- @logic Logic.py:1376 — too seed-specific; deferred until win-condition needs it.
function M.WinConditionMet() return false end

-- @logic Logic.py:1092
function M.CanBuy(_loc, _empty) return true end
function M.AnyKongCanBuy(_loc, _empty) return true end
function M.PurchaseShopItem(_loc) return true end

function M.GetCoins(_kong) return count("coins") end
function M.HasAccess(_region, _kong) return true end
function M.TimeAccess(_region, _time) return true end
function M.BlueprintAccess(_item) return true end
function M.HintAccess(_loc, _region) return true end

-- =============================================================================
-- Colored bananas — used in the medal threshold lambdas.
-- =============================================================================
function M.cb(level, kong)
  -- dk64pt currently doesn't shard CB counts per (level, kong); approximation:
  -- expose a single per-(level,kong) attribute fallback for testing, and
  -- aggregate via tracker codes once a CB-rando layout is wired.
  local probe_code = "cb_" .. tostring(level) .. "_" .. tostring(kong)
  if M.attrs and M.attrs[probe_code] ~= nil then return count(probe_code) end
  return count(probe_code)
end

-- =============================================================================
-- Helm puzzle / K. Rool ordering attributes.
-- These are pass-throughs from settings; lambdas read them as state.HelmDonkey1 etc.
-- =============================================================================
local function passthrough_setting(opt_name)
  return function() return settings[opt_name]() end
end
M.HelmDonkey1 = passthrough_setting("helm_donkey_1")
M.HelmDonkey2 = passthrough_setting("helm_donkey_2")
M.HelmDiddy1  = passthrough_setting("helm_diddy_1")
M.HelmDiddy2  = passthrough_setting("helm_diddy_2")
M.HelmLanky1  = passthrough_setting("helm_lanky_1")
M.HelmLanky2  = passthrough_setting("helm_lanky_2")
M.HelmTiny1   = passthrough_setting("helm_tiny_1")
M.HelmTiny2   = passthrough_setting("helm_tiny_2")
M.HelmChunky1 = passthrough_setting("helm_chunky_1")
M.HelmChunky2 = passthrough_setting("helm_chunky_2")

return M
