-- state_stub.lua — minimal `state` for the spike harness. Phase C will replace this
-- with a real adapter that reads PopTracker item codes. For now it's a plain table of
-- booleans you can mutate from the harness, plus a tiny helper API.

local M = {}

-- Bag of attribute booleans. Keys mirror LogicVarHolder attributes used in lambdas:
-- donkey, diddy, lanky, tiny, chunky, coconut, peanut, grape, feather, pineapple,
-- climbing, vines, swim, oranges, barrels, can_use_vines, cannons, camera, blast,
-- chunky helpers (hunkyChunky, punch, ...), Slam, isdonkey, isdiddy, ..., etc.
M.attrs = {}

-- Hook back to graph.lua's event table, set by the harness.
M._event_lookup = function(_) return false end

local function bool_attr(name)
  return function() return M.attrs[name] == true end
end

setmetatable(M, {
  __index = function(_, key)
    -- Default: any attribute access returns a function returning attrs[key].
    return bool_attr(key)
  end,
})

-- Methods that lambdas call. Each one is overridable from the harness for testing.
function M.event(name) return M._event_lookup(name) end
function M.special_loc(_) return false end
function M.has_item(name) return M.attrs["item_" .. name] == true end
function M.cb(level, kong) return (M.attrs["cb_" .. level .. "_" .. kong]) or 0 end

-- LogicVarHolder helpers (stubs — replaced in Phase C).
function M.CanPhase() return M.attrs.phasewalk == true end
function M.CanPhaseswim() return M.attrs.phaseswim == true and M.attrs.swim == true end
function M.CanSkew(_swim, _japes, _kong) return M.attrs.skew == true end
function M.CanMoonkick() return M.attrs.moonkicks == true end
function M.CanMoontail() return M.attrs.moontail == true end
function M.CanSTS() return false end
function M.CanOStandTBSNoclip() return false end
function M.CanAccessRNDRoom() return false end
function M.CanGetOnCannonGamePlatform() return false end
function M.CanSlamSwitch(_level, _req) return M.attrs.Slam == true end
function M.CanSlamChunkyPhaseSwitch() return M.attrs.Slam == true and M.attrs.chunky == true end
function M.hasMoveSwitchsanity(_switch, _is_owned) return false end
function M.checkBarrier(_barrier) return false end
function M.checkFastCheck(_check) return false end
function M.HasKong(kong) return M.attrs[kong] == true end
function M.IsKong(kong) return M.attrs["is" .. kong] == true end
function M.HasGun(_) return false end
function M.HasInstrument(_) return false end
function M.HasEnoughKongs(_) return false end
function M.HasFillRequirementsForLevel(_) return true end
function M.HasEnoughRaceCoins(_, _, _) return false end
function M.IsHardFallDamage() return false end
function M.IsLavaWater() return false end
function M.IsBossReachable(_) return false end
function M.IsBossBeatable(_) return false end
function M.IsLevelEnterable(_) return true end
function M.IsKLumsyFree() return false end
function M.LevelEntered(_) return false end
function M.HardBossesSettingEnabled(_) return false end
function M.canAccessHelm() return false end
function M.galleonGatesStayOpen() return false end
function M.cabinBarrelMoved() return false end
function M.canOpenLlamaTemple() return false end
function M.canTravelToMechFish() return false end
function M.canFulfillProgHint(_) return false end
function M.canFreeDiddy() return false end
function M.CanFreeDiddy() return false end
function M.CanFreeTiny() return false end
function M.CanFreeLanky() return false end
function M.CanFreeChunky() return false end
function M.CanLlamaSpit() return false end
function M.CanOpenJapesGates() return false end
function M.CanOpenForestLobbyGoneDoor() return false end
function M.CanGetRarewareCoin() return false end
function M.CanGetRarewareGB() return false end
function M.CanGetBlueprintReward(_) return false end
function M.CanBeatLankyPhase() return false end
function M.CanSurviveFallDamage() return true end
function M.CanAccessKRool() return false end
function M.CrownDoorOpened() return false end
function M.CoinDoorOpened() return false end
function M.WinConditionMet() return false end
function M.HasAllItems() return false end
function M.PurchaseShopItem(_) return true end
function M.AddCollectible(_, _) end
function M.UpdateCoins() end
function M.AddEvent(_) end
function M.SetKong(_) end
function M.GetKongs() return {} end
function M.UpdateKongs() end
function M.ItemCheck(_, _) return false end
function M.ItemCounts() return {} end
function M.GetCoins(_) return 0 end
function M.HasAccess(_, _) return false end
function M.TimeAccess(_, _) return false end
function M.BlueprintAccess(_) return false end
function M.HintAccess(_, _) return false end
function M.CanBuy(_, _) return false end
function M.AnyKongCanBuy(_, _) return false end
function M.isKrushaAdjacent(_) return false end
function M.isPriorHelmComplete(_) return false end

return M
