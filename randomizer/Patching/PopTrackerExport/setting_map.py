"""Single source of truth for randomizer ↔ dk64pt PopTracker mappings.

Two responsibilities:

1. **Document** which LogicVarHolder attributes/methods, settings, events, and
   enum members are expected to appear in randomizer/LogicFiles. Each entry
   carries an inline comment naming the dk64pt tracker code (or "(unsurfaced)"
   if the tracker doesn't yet expose it).

2. **Validate** the actual reference set produced by the AST transpiler. Any
   name that shows up in a lambda but isn't catalogued here causes the
   generator to fail loudly — this is the early-warning system for randomizer
   logic changes that the tracker hasn't kept up with.

When randomizer adds a new attribute/setting/glitch, add it here and pair it
with the corresponding state.lua / settings adapter change.
"""
from __future__ import annotations

from typing import Iterable, List

from .lambda_to_lua import AttrReferences

# =============================================================================
# state.<attr>()  — LogicVarHolder boolean attributes (no args).
# Comment after each name = the dk64pt PopTracker code state.lua reads from.
# =============================================================================
STATE_ATTRS: set = {
    # Kongs.
    "donkey",    # tracker: "donkey"
    "diddy",     # tracker: "diddy"
    "lanky",     # tracker: "lanky"
    "tiny",      # tracker: "tiny"
    "chunky",    # tracker: "chunky"
    # NOTE: l.isdonkey/diddy/lanky/tiny/chunky are rewritten to the base kong attribute
    # by the transpiler (tag_anywhere is always on under AP). state.lua does not need
    # is<kong> helpers — see lambda_to_lua._attribute ISX_ALIAS.
    "kong",      # current kong index (always 0 in tracker)

    # Weapons (kong-gated).
    "coconut",    # tracker: "donkey"+"coconut"
    "peanut",     # tracker: "diddy"+"peanuts"
    "grape",      # tracker: "lanky"+"grape"
    "feather",    # tracker: "tiny"+"feather"
    "pineapple",  # tracker: "chunky"+"pineapple"

    # Instruments (kong-gated).
    "bongos",     # tracker: "donkey"+"bongos"
    "guitar",     # tracker: "diddy"+"guitar"
    "trombone",   # tracker: "lanky"+"trombone"
    "saxophone",  # tracker: "tiny"+"sax"
    "triangle",   # tracker: "chunky"+"triangle"

    # Active moves (kong-gated).
    "blast",       # donkey+"blast"
    "strongKong",  # donkey+"strong"
    "grab",        # donkey+"grab"
    "charge",      # diddy+"charge"
    "jetpack",     # diddy+"rocket"
    "spring",      # diddy+"spring"
    "handstand",   # lanky+"orangstand"
    "balloon",     # lanky+"balloon"
    "sprint",      # lanky+"sprint"
    "mini",        # tiny+"mini"
    "twirl",       # tiny+"twirl"
    "monkeyport",  # tiny+"port"
    "hunkyChunky", # chunky+"big"
    "punch",       # chunky+"punch"
    "gorillaGone", # chunky+"gone"

    # Training barrels + shared.
    "barrels",       # tracker: "barrel"
    "swim",          # tracker: "dive"
    "oranges",       # tracker: "oranges"
    "climbing",      # tracker: "climb"
    "cannons",       # tracker: "cannons"|"cannon"
    "can_use_vines", # = vines

    # Specials.
    "camera",     # tracker: "camera"
    "shockwave",  # tracker: "shockwave"
    "scope",      # tracker: "sniper"
    "homing",     # tracker: "homing"

    # Slam ladder.
    "Slam",       # progressive count >=1
    "superSlam",  # progressive count >=2

    # Keys.
    "JapesKey",   # k1
    "AztecKey",   # k2
    "FactoryKey", # k3
    "GalleonKey", # k4
    "ForestKey",  # k5
    "CavesKey",   # k6
    "CastleKey",  # k7
    "HelmKey",    # k8

    # Counts that lambdas read as values.
    "Beans",  # tracker: count("bean")
    "Pearls", # tracker: count("pearl")
    "Melons", # approximation; tracker doesn't model current melons

    # Glitch / trick / setting-derived flags.
    "phasewalk", "phaseswim", "phasefall", "moonkicks", "moontail", "ledgeclip",
    "generalclips", "lanky_blocker_skip", "dk_blocker_skip", "troff_skip",
    "spawn_snags", "swim_through_shores", "skew", "tbs", "boulder_clip",
    "monkey_maneuvers", "hard_shooting", "advanced_grenading", "slope_resets",
    "adv_orange_usage",

    # Region-/area-access flags driven by settings or NPC presence.
    "snideAccess", "crankyAccess", "candyAccess", "funkyAccess",
    "dayAccess", "nightAccess",
    "allTrainingChecks",

    # Helm puzzle ordering — pass-throughs to settings.
    "HelmDonkey1", "HelmDonkey2", "HelmDiddy1", "HelmDiddy2",
    "HelmLanky1",  "HelmLanky2",  "HelmTiny1",  "HelmTiny2",
    "HelmChunky1", "HelmChunky2",

    # Always-false fill assumptions.
    "assumeAztecEntry", "assumeKRoolAccess", "assumeLevel4Entry",
    "assumeLevel5Entry", "assumeLevel7Entry", "assumeLevel8Entry",
    "assumeUpperIslesAccess",
}

# =============================================================================
# state.<method>(...)  — LogicVarHolder methods called by lambdas.
# state.lua hand-ports each of these; see the @logic Logic.py:<line> annotations.
# =============================================================================
STATE_METHODS: set = {
    "CanPhase", "CanPhaseswim", "CanSkew", "CanMoonkick", "CanMoontail",
    "CanSTS", "CanOStandTBSNoclip", "CanAccessRNDRoom", "CanGetOnCannonGamePlatform",
    "CanSlamSwitch", "CanSlamChunkyPhaseSwitch",
    "CanFreeDiddy", "CanFreeTiny", "CanFreeLanky", "CanFreeChunky",
    "CanLlamaSpit", "CanOpenJapesGates", "CanOpenForestLobbyGoneDoor",
    "canOpenLlamaTemple", "canTravelToMechFish", "canAccessHelm",
    "CanBeatLankyPhase", "CanSurviveFallDamage", "CanAccessKRool",
    "CanGetRarewareCoin", "CanGetRarewareGB", "CanGetBlueprintReward",
    "CanBuy",
    "checkBarrier", "checkFastCheck",
    "HasKong", "IsKong", "HasGun", "HasInstrument",
    "HasFillRequirementsForLevel", "HasEnoughRaceCoins",
    "hasMoveSwitchsanity",
    "isKrushaAdjacent", "isPriorHelmComplete",
    "IsBossBeatable", "IsBossReachable", "IsLavaWater", "IsHardFallDamage",
    "IsLevelEnterable",
    "CrownDoorOpened", "CoinDoorOpened", "WinConditionMet",
    "GetCoins", "TimeAccess",
    "cabinBarrelMoved", "galleonGatesStayOpen",
}

# =============================================================================
# settings.<attr>()  — scalar/tabular settings.
# settings_stub.lua / the production settings adapter must surface each.
# =============================================================================
SETTINGS_ATTRS: set = {
    # Toggles.
    "fast_start_beginning_of_game", "free_trade_items", "shuffle_shops",
    "open_lobbies", "auto_keys", "crown_placement_rando", "kasplat_rando",
    "tns_location_rando", "perma_death", "wipe_file_on_death",
    "wrinkly_location_rando", "remove_wrinkly_puzzles", "cannons_require_blast",

    # Enum-valued.
    "fungi_time_internal", "galleon_water_internal", "bonus_barrels",
    "diddy_freeing_kong", "tiny_freeing_kong", "lanky_freeing_kong",
    "chunky_freeing_kong", "helm_setting",

    # Helm puzzle slots (kong assignment per phase).
    "helm_donkey", "helm_diddy", "helm_lanky", "helm_tiny", "helm_chunky",

    # K. Rool order toggles.
    "krool_donkey", "krool_diddy", "krool_lanky", "krool_tiny", "krool_chunky",
    "krool_dillo1", "krool_dillo2", "krool_dog1", "krool_dog2",
    "krool_kutout", "krool_madjack", "krool_pufftoss",

    # Tabular (subscripted via settings.X(idx)).
    "level_order", "medal_cb_req_level", "mermaid_gb_pearls",
}

# =============================================================================
# settings.<list>_contains(member) — list-style settings used in `in` membership.
# =============================================================================
SETTINGS_LISTS: set = {
    "shuffled_location_types",
    # The transpiler also generates _contains() forms for these implicitly via state.lua's
    # glitch()/trick() helpers — they're listed here so the validator doesn't flag them.
    "glitches_selected",
    "tricks_selected",
    "removed_barriers_selected",
    "faster_checks_selected",
    "hard_mode_selected",
    "hard_bosses_selected",
    "misc_changes_selected",
}

# =============================================================================
# Enum classes whose members can appear as Levels.X / Switches.X / etc.
# Membership is open-ended (the randomizer adds new enum members over time);
# the validator only flags references whose CLASS isn't catalogued.
# =============================================================================
ENUM_CLASSES: set = {
    "Kongs", "Levels", "Regions", "Switches", "Events", "Locations",
    "Maps", "Items", "Time", "Transitions", "MinigameType", "HintRegion",
    "Collectibles", "Types", "BarrierItems",
    "RemovedBarriersSelected", "FasterChecksSelected", "GlitchesSelected",
    "TricksSelected", "HardModeSelected", "HardBossesSelected",
    "MiscChangesSelected", "ProgressiveHintItem", "BananaportRando",
    "ShuffleLoadingZones", "TrainingBarrels", "ShockwaveStatus",
    "ClimbingStatus", "CannonStatus", "DamageAmount", "LogicType",
    "ActivateAllBananaports", "HelmSetting", "KongModels", "SlamRequirement",
    "WinConditionComplex", "SwitchType", "ShuffleDoors",
    "MinigameBarrels", "GalleonWaterSetting", "FungiTimeSetting", "CBRando",
}


def validate(refs: AttrReferences) -> List[str]:
    """Return a list of human-readable validation problems for the given reference set.

    Empty list = clean. Each entry is a sentence describing the unmapped name and
    what category it should be added to.
    """
    problems: List[str] = []

    unmapped_state_attrs = sorted(refs.state_attrs - STATE_ATTRS)
    for name in unmapped_state_attrs:
        problems.append(
            f"state attribute `l.{name}` is not catalogued — add to STATE_ATTRS in setting_map.py "
            f"and surface state.{name}() in state.lua."
        )

    unmapped_state_methods = sorted(refs.state_methods - STATE_METHODS)
    for name in unmapped_state_methods:
        problems.append(
            f"state method `l.{name}(...)` is not catalogued — add to STATE_METHODS in setting_map.py "
            f"and port state.{name}(...) in state.lua."
        )

    unmapped_settings = sorted(refs.settings_attrs - SETTINGS_ATTRS)
    for name in unmapped_settings:
        problems.append(
            f"setting `l.settings.{name}` is not catalogued — add to SETTINGS_ATTRS in setting_map.py "
            f"and surface settings.{name}() in the settings adapter."
        )

    unmapped_lists = sorted(refs.settings_lists - SETTINGS_LISTS)
    for name in unmapped_lists:
        problems.append(
            f"setting list `<x> in l.settings.{name}` is not catalogued — add to SETTINGS_LISTS "
            f"in setting_map.py."
        )

    unmapped_enum_classes = sorted(set(refs.enum_members.keys()) - ENUM_CLASSES)
    for cls in unmapped_enum_classes:
        members = ", ".join(sorted(refs.enum_members[cls])[:3])
        problems.append(
            f"enum class `{cls}` (with members {members}, ...) is not catalogued — add to "
            f"ENUM_CLASSES in setting_map.py and ENUM_AS_STRING in lambda_to_lua.py."
        )

    return problems


def all_known_names() -> dict:
    """Convenience: return the full catalogue as a dict keyed by category."""
    return {
        "state_attrs": sorted(STATE_ATTRS),
        "state_methods": sorted(STATE_METHODS),
        "settings_attrs": sorted(SETTINGS_ATTRS),
        "settings_lists": sorted(SETTINGS_LISTS),
        "enum_classes": sorted(ENUM_CLASSES),
    }


def categories() -> Iterable[str]:
    return ("state_attrs", "state_methods", "settings_attrs", "settings_lists", "enum_classes")
