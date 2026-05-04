-- AUTO-GENERATED SPIKE OUTPUT — do not hand-edit.
-- Source: randomizer/LogicFiles/JungleJapes.py

local M = {}
M.regions = {}

-- region: JungleJapesMedals
M.regions["JungleJapesMedals"] = {
  locations = {
    { id = "JapesDonkeyMedal", logic = function() return (state.cb("JungleJapes", "donkey") >= settings.medal_cb_req_level(0)) end },
    { id = "JapesDiddyMedal", logic = function() return (state.cb("JungleJapes", "diddy") >= settings.medal_cb_req_level(0)) end },
    { id = "JapesLankyMedal", logic = function() return (state.cb("JungleJapes", "lanky") >= settings.medal_cb_req_level(0)) end },
    { id = "JapesTinyMedal", logic = function() return (state.cb("JungleJapes", "tiny") >= settings.medal_cb_req_level(0)) end },
    { id = "JapesChunkyMedal", logic = function() return (state.cb("JungleJapes", "chunky") >= settings.medal_cb_req_level(0)) end },
    { id = "JapesDonkeyHalfMedal", logic = function() return (state.cb("JungleJapes", "donkey") >= math.max(1, math.floor(math.floor(settings.medal_cb_req_level(0) / (2 ^ 1))))) end },
    { id = "JapesDiddyHalfMedal", logic = function() return (state.cb("JungleJapes", "diddy") >= math.max(1, math.floor(math.floor(settings.medal_cb_req_level(0) / (2 ^ 1))))) end },
    { id = "JapesLankyHalfMedal", logic = function() return (state.cb("JungleJapes", "lanky") >= math.max(1, math.floor(math.floor(settings.medal_cb_req_level(0) / (2 ^ 1))))) end },
    { id = "JapesTinyHalfMedal", logic = function() return (state.cb("JungleJapes", "tiny") >= math.max(1, math.floor(math.floor(settings.medal_cb_req_level(0) / (2 ^ 1))))) end },
    { id = "JapesChunkyHalfMedal", logic = function() return (state.cb("JungleJapes", "chunky") >= math.max(1, math.floor(math.floor(settings.medal_cb_req_level(0) / (2 ^ 1))))) end },
  },
  events = {
  },
  exits = {
  },
}

-- region: JungleJapesEntryHandler
M.regions["JungleJapesEntryHandler"] = {
  locations = {
  },
  events = {
    { id = "JapesEntered", logic = function() return true end },
  },
  exits = {
    { id = "JungleJapesLobby", logic = function() return true end },  -- exitShuffleId='Transitions.JapesToIsles'
    { id = "JungleJapesStart", logic = function() return true end },
  },
}

-- region: JungleJapesStart
M.regions["JungleJapesStart"] = {
  locations = {
    { id = "JapesDonkeyCagedBanana", logic = function() return (((state.event("JapesDonkeySwitch") or state.CanPhaseswim() or state.CanSkew(true) or state.CanSkew(false)) and state.donkey()) or ((state.CanPhaseswim() or state.CanSkew(true) or state.CanSkew(false)) and settings.free_trade_items())) end },
    { id = "JapesChunkyBoulder", logic = function() return (state.chunky() and state.barrels()) end },
    { id = "Balloon006", logic = function() return (state.donkey() and state.coconut()) end },
    { id = "JapesMainEnemy_Start", logic = function() return true end },
    { id = "JapesMainEnemy_Tunnel0", logic = function() return true end },
    { id = "JapesMainEnemy_Tunnel1", logic = function() return true end },
    { id = "JapesMainEnemy_KilledInDemo", logic = function() return true end },
    { id = "JapesMainEnemy_NearUnderground", logic = function() return true end },
    { id = "KremKap_JapesMainEnemy_Start", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_Tunnel0", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_Tunnel1", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_KilledInDemo", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_NearUnderground", logic = function() return state.camera() end },
  },
  events = {
    { id = "JapesW1aTagged", logic = function() return true end },
    { id = "JapesW1bTagged", logic = function() return true end },
    { id = "JapesW2aTagged", logic = function() return true end },
    { id = "JapesW3bTagged", logic = function() return true end },
  },
  exits = {
    { id = "JungleJapesMain", logic = function() return true end },
    { id = "JapesHill", logic = function() return state.climbing() end },
    { id = "JapesBeyondPeanutGate", logic = function() return (state.hasMoveSwitchsanity("JapesDiddyCave", false) or state.CanPhase() or state.CanPhaseswim() or state.CanSkew(true) or state.CanSkew(false) or state.generalclips()) end },
    { id = "JapesBeyondCoconutGate1", logic = function() return (state.checkBarrier("japes_coconut_gates") or state.event("JapesFreeKongOpenGates") or state.CanPhase() or state.CanPhaseswim() or state.CanSkew(true) or state.CanSkew(false) or state.generalclips()) end },
    { id = "JapesBeyondCoconutGate2", logic = function() return (state.checkBarrier("japes_coconut_gates") or state.event("JapesFreeKongOpenGates") or state.CanPhase() or state.CanPhaseswim() or state.CanSkew(true) or state.CanSkew(false) or state.generalclips()) end },
    { id = "JapesCatacomb", logic = function() return ((state.Slam() and state.chunky() and state.barrels()) or state.CanPhaseswim() or state.CanSkew(true) or state.CanSkew(false)) end },  -- exitShuffleId='Transitions.JapesMainToCatacomb'
    { id = "JapesBlastPadPlatform", logic = function() return ((state.can_use_vines() or state.CanMoonkick()) and state.climbing() and (state.isdonkey() or state.isdiddy() or state.ischunky())) end },
  },
}

-- region: JapesBlastPadPlatform
M.regions["JapesBlastPadPlatform"] = {
  locations = {
  },
  events = {
  },
  exits = {
    { id = "JungleJapesStart", logic = function() return true end },
    { id = "JapesBaboonBlast", logic = function() return (state.blast() and state.isdonkey()) end },
  },
}

-- region: JapesCannonPlatform
M.regions["JapesCannonPlatform"] = {
  locations = {
    { id = "JapesLankyCagedBanana", logic = function() return (((state.event("JapesLankySwitch") or ((not settings.shuffle_shops()) and state.CanSkew(true)) or state.CanSkew(false)) and state.lanky()) or (((not settings.shuffle_shops()) and state.CanSkew(true)) or (state.CanSkew(false) and settings.free_trade_items()))) end },
  },
  events = {
    { id = "JapesAccessToCannon", logic = function() return state.cannons() end },
  },
  exits = {
    { id = "JapesHillTop", logic = function() return state.cannons() end },
    { id = "JungleJapesMain", logic = function() return true end },
    { id = "JapesHill", logic = function() return state.can_use_vines() end },
  },
}

-- region: JapesHillTop
M.regions["JapesHillTop"] = {
  locations = {
    { id = "DiddyKong", logic = function() return state.CanFreeDiddy() end },
    { id = "Balloon002", logic = function() return (state.isdonkey() and state.coconut()) end },
    { id = "JapesDonkeyFrontofCage", logic = function() return (state.HasKong(settings.diddy_freeing_kong()) or settings.free_trade_items()) end },
    { id = "JapesDonkeyFreeDiddy", logic = function() return state.event("JapesFreeKongOpenGates") end },
    { id = "MelonCrate_Location00", logic = function() return true end },
    { id = "JapesMainEnemy_Mountain", logic = function() return true end },
    { id = "KremKap_JapesMainEnemy_Mountain", logic = function() return state.camera() end },
    { id = "JapesChunkyCagedBanana", logic = function() return (((state.event("JapesChunkySwitch") or state.CanPhase() or ((not settings.shuffle_shops()) and (state.CanSkew(true) or state.CanSkew(false)))) and state.chunky()) or ((state.CanPhase() or ((not settings.shuffle_shops()) and (state.CanSkew(true) or state.CanSkew(false)))) and settings.free_trade_items())) end },
  },
  events = {
    { id = "JapesFreeKongOpenGates", logic = function() return state.CanOpenJapesGates() end },
    { id = "JapesW2bTagged", logic = function() return true end },
  },
  exits = {
    { id = "Snide", logic = function() return state.snideAccess() end },
    { id = "JapesTnSAlcove", logic = function() return (state.monkey_maneuvers() and (not state.IsHardFallDamage())) end },
    { id = "Mine", logic = function() return (state.peanut() and state.isdiddy()) end },  -- exitShuffleId='Transitions.JapesMainToMine'
    { id = "JapesTopOfMountain", logic = function() return ((state.peanut() and state.isdiddy()) or state.CanMoonkick()) end },
    { id = "JapesHill", logic = function() return true end },
    { id = "JapesCannonPlatform", logic = function() return true end },
    { id = "JungleJapesMain", logic = function() return true end },
  },
}

-- region: JapesHill
M.regions["JapesHill"] = {
  locations = {
    { id = "JapesDiddyCagedBanana", logic = function() return (((state.event("JapesDiddySwitch1") or state.CanPhase() or state.generalclips() or state.CanSkew(true) or state.CanSkew(false)) and state.diddy()) or ((state.CanPhase() or state.generalclips() or state.CanSkew(true) or state.CanSkew(false)) and settings.free_trade_items())) end },
    { id = "JapesBattleArena", logic = function() return (not settings.crown_placement_rando()) end },
  },
  events = {
  },
  exits = {
    { id = "JapesHillTop", logic = function() return state.climbing() end },
    { id = "JapesCannonPlatform", logic = function() return state.can_use_vines() end },
    { id = "FunkyJapes", logic = function() return state.funkyAccess() end },
    { id = "JungleJapesStart", logic = function() return true end },
  },
}

-- region: JungleJapesMain
M.regions["JungleJapesMain"] = {
  locations = {
    { id = "JapesTinyCagedBanana", logic = function() return (((state.event("JapesTinySwitch") or state.CanPhase() or state.CanPhaseswim() or state.CanSkew(true) or state.CanSkew(false)) and state.tiny()) or ((state.CanPhase() or state.CanPhaseswim() or state.CanSkew(true) or state.CanSkew(false)) and settings.free_trade_items())) end },
    { id = "JapesMainEnemy_NearPainting0", logic = function() return true end },
    { id = "JapesMainEnemy_NearPainting1", logic = function() return true end },
    { id = "JapesMainEnemy_NearPainting2", logic = function() return true end },
    { id = "KremKap_JapesMainEnemy_NearPainting0", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_NearPainting1", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_NearPainting2", logic = function() return state.camera() end },
  },
  events = {
    { id = "JapesW3aTagged", logic = function() return true end },
  },
  exits = {
    { id = "JungleJapesStart", logic = function() return true end },
    { id = "JapesCannonPlatform", logic = function() return ((state.handstand() and state.lanky() and state.monkey_maneuvers()) or ((not state.isKrushaAdjacent("tiny")) and state.tiny() and state.slope_resets())) end },
    { id = "JapesBeyondCoconutGate2", logic = function() return (state.checkBarrier("japes_coconut_gates") or state.event("JapesFreeKongOpenGates") or state.CanPhase() or state.CanPhaseswim() or state.CanSkew(true) or state.CanSkew(false) or state.generalclips()) end },
    { id = "JapesPaintingRoomHill", logic = function() return ((state.handstand() and state.islanky()) or (state.twirl() and state.istiny() and state.climbing()) or state.CanMoonkick() or state.CanSkew(true) or state.CanSkew(false) or state.slope_resets()) end },
    { id = "JapesLankyCave", logic = function() return (((state.hasMoveSwitchsanity("JapesPainting", false) or state.CanSkew(true) or state.CanSkew(false)) and ((state.handstand() and state.islanky()) or (state.twirl() and state.istiny() and state.climbing()) or state.CanMoonkick() or state.slope_resets())) or (state.CanMoonkick() and (state.CanPhase() or state.CanSkew(true) or state.CanSkew(false))) or ((state.CanPhase() or state.generalclips() or state.CanSkew(true) or state.CanSkew(false)) and (state.isdiddy() or state.istiny()))) end },  -- exitShuffleId='Transitions.JapesMainToLankyCave', isGlitchTransition='True'
    { id = "BeyondRambiGate", logic = function() return (state.CanPhaseswim() or state.CanSkew(true) or state.CanSkew(false) or state.CanPhase() or state.generalclips()) end },
    { id = "JapesTnSAlcove", logic = function() return ((state.can_use_vines() or state.CanMoonkick()) and state.climbing()) end },
  },
}

-- region: JapesPaintingRoomHill
M.regions["JapesPaintingRoomHill"] = {
  locations = {
    { id = "RainbowCoin_Location00", logic = function() return true end },
  },
  events = {
  },
  exits = {
    { id = "JungleJapesMain", logic = function() return true end },
    { id = "JapesLankyCave", logic = function() return (state.hasMoveSwitchsanity("JapesPainting", false) or state.CanSkew(true) or state.CanSkew(false) or state.CanPhase()) end },  -- exitShuffleId='Transitions.JapesMainToLankyCave'
  },
}

-- region: JapesTnSAlcove
M.regions["JapesTnSAlcove"] = {
  locations = {
  },
  events = {
  },
  exits = {
    { id = "JungleJapesMain", logic = function() return true end },
    { id = "JapesBossLobby", logic = function() return (not settings.tns_location_rando()) end },
  },
}

-- region: JapesTopOfMountain
M.regions["JapesTopOfMountain"] = {
  locations = {
    { id = "JapesDiddyMountain", logic = function() return (state.event("JapesDiddySwitch2") and (state.isdiddy() or settings.free_trade_items())) end },
    { id = "Balloon005", logic = function() return (state.isdiddy() and state.peanut()) end },
  },
  events = {
    { id = "JapesW5bTagged", logic = function() return state.special_loc("JapesDiddyMountain") end },
  },
  exits = {
    { id = "JapesHillTop", logic = function() return true end },
  },
}

-- region: JapesBaboonBlast
M.regions["JapesBaboonBlast"] = {
  locations = {
    { id = "JapesDonkeyBaboonBlast", logic = function() return state.isdonkey() end },
  },
  events = {
  },
  exits = {
    { id = "JapesBlastPadPlatform", logic = function() return true end },
  },
}

-- region: JapesBeyondPeanutGate
M.regions["JapesBeyondPeanutGate"] = {
  locations = {
    { id = "Balloon001", logic = function() return (state.isdiddy() and state.peanut()) end },
    { id = "JapesDiddyTunnel", logic = function() return (state.isdiddy() or settings.free_trade_items()) end },
    { id = "JapesLankyGrapeGate", logic = function() return ((state.grape() and state.islanky()) or ((state.CanPhase() or state.generalclips() or state.CanSkew(true) or state.CanSkew(false)) and (state.islanky() or settings.free_trade_items()))) end },  -- bonusBarrel='MinigameType.BonusBarrel'
    { id = "JapesTinyFeatherGateBarrel", logic = function() return ((state.feather() and state.istiny()) or ((state.CanPhase() or state.CanSkew(true) or state.CanSkew(false)) and (state.istiny() or settings.free_trade_items()))) end },  -- bonusBarrel='MinigameType.BonusBarrel'
    { id = "JapesMainEnemy_DiddyCavern", logic = function() return true end },
    { id = "KremKap_JapesMainEnemy_DiddyCavern", logic = function() return state.camera() end },
  },
  events = {
  },
  exits = {
    { id = "JungleJapesStart", logic = function() return true end },
    { id = "JapesBossLobby", logic = function() return (not settings.tns_location_rando()) end },
  },
}

-- region: JapesBeyondCoconutGate1
M.regions["JapesBeyondCoconutGate1"] = {
  locations = {
    { id = "JapesKasplatLeftTunnelNear", logic = function() return (not settings.kasplat_rando()) end },
    { id = "JapesKasplatLeftTunnelFar", logic = function() return (not settings.kasplat_rando()) end },
    { id = "JapesMainEnemy_FeatherTunnel", logic = function() return true end },
    { id = "KremKap_JapesMainEnemy_FeatherTunnel", logic = function() return state.camera() end },
  },
  events = {
  },
  exits = {
    { id = "JungleJapesStart", logic = function() return true end },
    { id = "JapesBeyondFeatherGate", logic = function() return (state.checkBarrier("japes_shellhive_gate") or state.hasMoveSwitchsanity("JapesFeather", false) or state.CanPhase() or state.CanSkew(true) or state.CanSkew(false)) end },
  },
}

-- region: JapesBeyondFeatherGate
M.regions["JapesBeyondFeatherGate"] = {
  locations = {
    { id = "JapesTinyStump", logic = function() return (((state.mini() and state.istiny()) or state.CanPhase() or state.CanSkew(true) or state.CanSkew(false)) and state.istiny()) end },
    { id = "JapesChunkyGiantBonusBarrel", logic = function() return (state.climbing() and state.hunkyChunky() and state.ischunky()) end },  -- bonusBarrel='MinigameType.BonusBarrel'
    { id = "JapesMainEnemy_Hive0", logic = function() return true end },
    { id = "JapesMainEnemy_Hive1", logic = function() return true end },
    { id = "JapesMainEnemy_Hive2", logic = function() return true end },
    { id = "JapesMainEnemy_Hive3", logic = function() return true end },
    { id = "JapesMainEnemy_Hive4", logic = function() return true end },
    { id = "KremKap_JapesMainEnemy_Hive0", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_Hive1", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_Hive2", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_Hive3", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_Hive4", logic = function() return state.camera() end },
  },
  events = {
    { id = "JapesW5aTagged", logic = function() return true end },
  },
  exits = {
    { id = "JapesBeyondCoconutGate1", logic = function() return true end },
    { id = "TinyHive", logic = function() return ((state.mini() and state.istiny()) or state.CanPhase() or state.CanSkew(true) or state.CanSkew(false) or (state.hunkyChunky() and state.ischunky() and state.generalclips())) end },  -- exitShuffleId='Transitions.JapesMainToTinyHive'
    { id = "BeyondRambiGate", logic = function() return (state.hunkyChunky() and state.ischunky() and state.generalclips()) end },
  },
}

-- region: TinyHive
M.regions["TinyHive"] = {
  locations = {
    { id = "JapesTinyBeehive", logic = function() return ((state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips())) or (settings.free_trade_items() and state.CanPhase())) end },
    { id = "JapesShellhiveEnemy_FirstRoom", logic = function() return true end },
    { id = "JapesShellhiveEnemy_SecondRoom0", logic = function() return (state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips())) end },
    { id = "JapesShellhiveEnemy_SecondRoom1", logic = function() return (state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips())) end },
    { id = "JapesShellhiveEnemy_ThirdRoom0", logic = function() return (state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips())) end },
    { id = "JapesShellhiveEnemy_ThirdRoom1", logic = function() return (state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips())) end },
    { id = "JapesShellhiveEnemy_ThirdRoom2", logic = function() return (state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips())) end },
    { id = "JapesShellhiveEnemy_ThirdRoom3", logic = function() return (state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips())) end },
    { id = "JapesShellhiveEnemy_MainRoom", logic = function() return true end },
    { id = "KremKap_JapesShellhiveEnemy_FirstRoom", logic = function() return state.camera() end },
    { id = "KremKap_JapesShellhiveEnemy_SecondRoom0", logic = function() return (state.camera() and (state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips()))) end },
    { id = "KremKap_JapesShellhiveEnemy_SecondRoom1", logic = function() return (state.camera() and (state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips()))) end },
    { id = "KremKap_JapesShellhiveEnemy_ThirdRoom0", logic = function() return (state.camera() and (state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips()))) end },
    { id = "KremKap_JapesShellhiveEnemy_ThirdRoom1", logic = function() return (state.camera() and (state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips()))) end },
    { id = "KremKap_JapesShellhiveEnemy_ThirdRoom2", logic = function() return (state.camera() and (state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips()))) end },
    { id = "KremKap_JapesShellhiveEnemy_ThirdRoom3", logic = function() return (state.camera() and (state.istiny() and ((state.CanSlamSwitch("JungleJapes", 1) and (state.saxophone() or state.oranges())) or state.CanPhase() or state.generalclips()))) end },
    { id = "KremKap_JapesShellhiveEnemy_MainRoom", logic = function() return state.camera() end },
    { id = "Balloon013", logic = function() return (state.istiny() and state.feather()) end },
  },
  events = {
  },
  exits = {
    { id = "JapesBeyondFeatherGate", logic = function() return (state.isdiddy() or state.istiny() or state.islanky() or state.CanPhase()) end },  -- exitShuffleId='Transitions.JapesTinyHiveToMain'
  },
}

-- region: JapesBeyondCoconutGate2
M.regions["JapesBeyondCoconutGate2"] = {
  locations = {
    { id = "JapesLankySlope", logic = function() return ((state.handstand() and state.islanky()) or state.slope_resets()) end },  -- bonusBarrel='MinigameType.BonusBarrel'
    { id = "JapesKasplatNearPaintingRoom", logic = function() return (not settings.kasplat_rando()) end },
    { id = "JapesKasplatNearLab", logic = function() return (not settings.kasplat_rando()) end },
    { id = "JapesMainEnemy_Storm0", logic = function() return true end },
    { id = "JapesMainEnemy_Storm1", logic = function() return true end },
    { id = "JapesMainEnemy_Storm2", logic = function() return true end },
    { id = "JapesMainEnemy_MiddleTunnel", logic = function() return true end },
    { id = "KremKap_JapesMainEnemy_Storm0", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_Storm1", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_Storm2", logic = function() return state.camera() end },
    { id = "KremKap_JapesMainEnemy_MiddleTunnel", logic = function() return state.camera() end },
    { id = "BreakableJapesDKHut", logic = function() return state.event("Rambi") end },
    { id = "BreakableJapesDiddyHut", logic = function() return state.event("Rambi") end },
    { id = "BreakableJapesLankyHut", logic = function() return state.event("Rambi") end },
    { id = "BreakableJapesTinyHut", logic = function() return state.event("Rambi") end },
    { id = "Balloon004", logic = function() return (state.lanky() and state.grape()) end },
    { id = "Balloon007", logic = function() return (state.donkey() and state.coconut()) end },
    { id = "Balloon008", logic = function() return (state.tiny() and state.feather()) end },
    { id = "Balloon012", logic = function() return (state.lanky() and state.grape()) end },
  },
  events = {
    { id = "Rambi", logic = function() return (state.hasMoveSwitchsanity("JapesRambi", false) or state.CanPhase()) end },
    { id = "JapesDonkeySwitch", logic = function() return ((state.event("Rambi") or state.CanPhase()) and state.CanSlamSwitch("JungleJapes", 1) and state.donkey()) end },
    { id = "JapesDiddySwitch1", logic = function() return ((state.event("Rambi") or state.CanPhase()) and state.CanSlamSwitch("JungleJapes", 1) and state.diddy()) end },
    { id = "JapesLankySwitch", logic = function() return ((state.event("Rambi") or state.CanPhase()) and state.CanSlamSwitch("JungleJapes", 1) and state.lanky()) end },
    { id = "JapesTinySwitch", logic = function() return ((state.event("Rambi") or state.CanPhase()) and state.CanSlamSwitch("JungleJapes", 1) and state.tiny()) end },
    { id = "JapesW4aTagged", logic = function() return true end },
    { id = "JapesW4bTagged", logic = function() return true end },
  },
  exits = {
    { id = "JungleJapesStart", logic = function() return true end },
    { id = "JungleJapesMain", logic = function() return true end },
    { id = "JapesUselessSlope", logic = function() return ((state.handstand() and state.islanky()) or state.CanPhase() or state.slope_resets()) end },
    { id = "BeyondRambiGate", logic = function() return (state.event("Rambi") or state.CanPhase() or state.CanSkew(true) or state.CanSkew(false)) end },
    { id = "CrankyJapes", logic = function() return state.crankyAccess() end },
    { id = "JapesBeyondFeatherGate", logic = function() return state.CanMoonkick() end },
  },
}

-- region: JapesUselessSlope
M.regions["JapesUselessSlope"] = {
  locations = {
  },
  events = {
  },
  exits = {
    { id = "JapesBeyondCoconutGate2", logic = function() return true end },
  },
}

-- region: BeyondRambiGate
M.regions["BeyondRambiGate"] = {
  locations = {
    { id = "JapesBananaFairyRambiCave", logic = function() return state.camera() end },
    { id = "MelonCrate_Location01", logic = function() return true end },
    { id = "Balloon003", logic = function() return (state.ischunky() and state.pineapple()) end },
    { id = "Balloon009", logic = function() return (state.istiny() and state.feather()) end },
    { id = "Balloon010", logic = function() return (state.ischunky() and state.pineapple()) end },
    { id = "Balloon011", logic = function() return (state.ischunky() and state.pineapple()) end },
  },
  events = {
    { id = "JapesChunkySwitch", logic = function() return (state.CanSlamSwitch("JungleJapes", 1) and state.ischunky() and state.barrels()) end },
  },
  exits = {
    { id = "JapesBeyondCoconutGate2", logic = function() return true end },
    { id = "JapesBossLobby", logic = function() return (not settings.tns_location_rando()) end },
  },
}

-- region: JapesLankyCave
M.regions["JapesLankyCave"] = {
  locations = {
    { id = "JapesLankyFairyCave", logic = function() return ((((state.grape() or state.trombone() or state.adv_orange_usage()) and state.Slam()) or state.generalclips()) and state.islanky()) end },
    { id = "JapesBananaFairyLankyCave", logic = function() return ((((state.grape() or state.trombone() or state.adv_orange_usage()) and state.Slam()) or state.generalclips()) and state.islanky() and state.camera()) end },
    { id = "Balloon014", logic = function() return (state.islanky() and state.grape()) end },
  },
  events = {
  },
  exits = {
    { id = "JapesPaintingRoomHill", logic = function() return true end },  -- exitShuffleId='Transitions.JapesLankyCaveToMain'
  },
}

-- region: Mine
M.regions["Mine"] = {
  locations = {
    { id = "Balloon000", logic = function() return (state.isdiddy() and (state.CanSlamSwitch("JungleJapes", 1) or state.CanPhase()) and state.peanut()) end },
    { id = "JapesMountainEnemy_Start0", logic = function() return true end },
    { id = "JapesMountainEnemy_Start1", logic = function() return true end },
    { id = "JapesMountainEnemy_Start2", logic = function() return true end },
    { id = "JapesMountainEnemy_Start3", logic = function() return true end },
    { id = "JapesMountainEnemy_Start4", logic = function() return true end },
    { id = "JapesMountainEnemy_NearGateSwitch0", logic = function() return true end },
    { id = "JapesMountainEnemy_NearGateSwitch1", logic = function() return true end },
    { id = "JapesMountainEnemy_HiLo", logic = function() return ((state.charge() and state.isdiddy()) or state.CanPhase()) end },
    { id = "JapesMountainEnemy_Conveyor0", logic = function() return ((state.CanSlamSwitch("JungleJapes", 1) and state.isdiddy()) or state.CanPhase()) end },
    { id = "JapesMountainEnemy_Conveyor1", logic = function() return ((state.CanSlamSwitch("JungleJapes", 1) and state.isdiddy()) or state.CanPhase()) end },
    { id = "KremKap_JapesMountainEnemy_Start0", logic = function() return state.camera() end },
    { id = "KremKap_JapesMountainEnemy_Start1", logic = function() return state.camera() end },
    { id = "KremKap_JapesMountainEnemy_Start2", logic = function() return state.camera() end },
    { id = "KremKap_JapesMountainEnemy_Start3", logic = function() return state.camera() end },
    { id = "KremKap_JapesMountainEnemy_Start4", logic = function() return state.camera() end },
    { id = "KremKap_JapesMountainEnemy_NearGateSwitch0", logic = function() return state.camera() end },
    { id = "KremKap_JapesMountainEnemy_NearGateSwitch1", logic = function() return state.camera() end },
    { id = "KremKap_JapesMountainEnemy_HiLo", logic = function() return (state.camera() and ((state.charge() and state.isdiddy()) or state.CanPhase())) end },
    { id = "KremKap_JapesMountainEnemy_Conveyor0", logic = function() return (state.camera() and ((state.CanSlamSwitch("JungleJapes", 1) and state.isdiddy()) or state.CanPhase())) end },
    { id = "KremKap_JapesMountainEnemy_Conveyor1", logic = function() return (state.camera() and ((state.CanSlamSwitch("JungleJapes", 1) and state.isdiddy()) or state.CanPhase())) end },
  },
  events = {
    { id = "JapesDiddySwitch2", logic = function() return (state.CanSlamSwitch("JungleJapes", 1) and (state.peanut() or state.monkey_maneuvers()) and state.isdiddy()) end },
  },
  exits = {
    { id = "JapesHillTop", logic = function() return true end },  -- exitShuffleId='Transitions.JapesMineToMain'
    { id = "JapesMinecarts", logic = function() return ((state.CanSlamSwitch("JungleJapes", 1) or state.CanPhase()) and ((state.charge() and state.isdiddy()) or state.CanPhase() or (state.monkey_maneuvers() and state.isdiddy()))) end },
  },
}

-- region: JapesMinecarts
M.regions["JapesMinecarts"] = {
  locations = {
    { id = "JapesDiddyMinecarts", logic = function() return state.HasEnoughRaceCoins("JapesMinecarts", "diddy", true) end },
  },
  events = {
  },
  exits = {
    { id = "JungleJapesMain", logic = function() return true end },
  },
}

-- region: JapesCatacomb
M.regions["JapesCatacomb"] = {
  locations = {
    { id = "JapesChunkyUnderground", logic = function() return ((state.can_use_vines() and state.pineapple() and state.ischunky()) or (((state.twirl() and state.istiny()) or (state.can_use_vines() and (state.isdiddy() or state.istiny())) or (state.isdonkey() and (not state.isKrushaAdjacent("donkey")))) and state.monkey_maneuvers() and settings.free_trade_items()) or state.CanPhase()) end },
    { id = "JapesKasplatUnderground", logic = function() return ((not settings.kasplat_rando()) and ((state.can_use_vines() and state.pineapple() and state.ischunky()) or (state.can_use_vines() and (state.isdiddy() or state.istiny()) and state.monkey_maneuvers() and settings.free_trade_items()) or state.CanPhase())) end },
  },
  events = {
  },
  exits = {
    { id = "JungleJapesStart", logic = function() return state.cannons() end },  -- exitShuffleId='Transitions.JapesCatacombToMain'
  },
}

-- region: JapesBossLobby
M.regions["JapesBossLobby"] = {
  locations = {
  },
  events = {
  },
  exits = {
    { id = "JapesBoss", logic = function() return state.IsBossReachable("JungleJapes") end },
  },
}

-- region: JapesBoss
M.regions["JapesBoss"] = {
  locations = {
    { id = "JapesKey", logic = function() return state.IsBossBeatable("JungleJapes") end },
  },
  events = {
  },
  exits = {
  },
}

return M