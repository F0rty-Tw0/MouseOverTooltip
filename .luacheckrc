-- .luacheckrc for MouseOverTooltip (WoW addon, all flavors)
-- Targets Lua 5.1 (WoW runtime)

std = "lua51"
max_line_length = false -- StyLua handles formatting; luacheck handles semantics
cache = true
jobs = 4

exclude_files = {
  ".luacheckrc",
  ".tools/",
}

ignore = {
  "212/self", -- unused 'self' in method definitions
  "211/addonName", -- unused first return from `local addonName, ns = ...`
  "212/addonName", -- same when treated as argument
  "331/ns", -- ns is set (mutated) then exported, not read directly
}

-- Globals the addon WRITES
globals = {
  -- SavedVariables (declared in .toc)
  "MouseOverTooltipDB",

  -- Slash command registration (Blizzard pattern)
  "SlashCmdList",
  "SLASH_MOUSEOVERTOOLTIP1",

  -- AddOn Compartment handlers (named in the .toc)
  "MouseOverTooltip_OnAddonCompartmentClick",
  "MouseOverTooltip_OnAddonCompartmentEnter",
  "MouseOverTooltip_OnAddonCompartmentLeave",
}

-- Globals the addon READS (WoW API surface used by this addon)
read_globals = {
  -- Frames and hooks
  "CreateFrame",
  "UIParent",
  "Minimap",
  "GameTooltip",
  "GameTooltipStatusBar",
  "GameTooltip_SetDefaultAnchor",
  "InspectFrame",
  "hooksecurefunc",
  "TooltipDataProcessor",
  "Enum",
  "Settings",
  "CreateSettingsListSectionHeaderInitializer",
  "MinimalSliderWithSteppersMixin",

  -- Namespaced APIs
  "C_BattleNet",
  "C_ChallengeMode",
  "C_FriendList",
  "C_Item",
  "C_MountJournal",
  "C_PaperDollInfo",
  "C_PlayerInfo",
  "C_Timer",
  "C_UnitAuras",

  -- Unit info
  "UnitAura",
  "UnitClass",
  "UnitClassification",
  "UnitCreatureType",
  "UnitExists",
  "UnitFactionGroup",
  "UnitGUID",
  "UnitIsAFK",
  "UnitIsConnected",
  "UnitIsDND",
  "UnitIsDead",
  "UnitIsGhost",
  "UnitIsPlayer",
  "UnitIsTapDenied",
  "UnitIsUnit",
  "UnitLevel",
  "UnitName",
  "UnitPVPName",
  "UnitRace",
  "UnitReaction",
  "UnitTokenFromGUID",
  "GetGuildInfo",
  "GetRaidTargetIndex",
  "GetNumGroupMembers",
  "IsInRaid",

  -- Inspect
  "CanInspect",
  "NotifyInspect",
  "ClearInspectPlayer",
  "GetInspectArenaData",
  "C_SpecializationInfo",
  "WOW_PROJECT_MISTS_CLASSIC",
  "WOW_PROJECT_CATACLYSM_CLASSIC",
  "UnitHealth",
  "UnitHealthMax",
  "GetInspectSpecialization",
  "GetSpecializationInfoByID",
  "GetSpecialization",
  "GetSpecializationInfo",
  "GetAverageItemLevel",

  -- Items and colors
  "GetItemInfo",
  "GetItemQualityColor",
  "GetDifficultyColor",
  "GetCreatureDifficultyColor",
  "GetQuestDifficultyColor",
  "AbbreviateLargeNumbers",
  "AbbreviateNumbers",
  "RAID_CLASS_COLORS",
  "FACTION_BAR_COLORS",
  "TOOLTIP_DEFAULT_COLOR",
  "TOOLTIP_UNIT_LEVEL",

  -- Misc
  "GetTime",
  "GetBuildInfo",
  "InCombatLockdown",
  "IsShiftKeyDown",
  "issecretvalue",
  "MDT",
  "WOW_PROJECT_ID",
  "WOW_PROJECT_MAINLINE",
}

-- Test files stub WoW globals freely
files["tests/**/*.lua"] = {
  globals = { "_G", "require" },
  ignore = {
    "111", -- setting undefined global (tests stub globals)
    "112", -- mutating undefined global
    "113", -- accessing undefined global
    "122", -- setting read-only field (tests stub read_globals)
    "142", -- setting undefined field of global
    "143", -- accessing undefined field of global
    "211", -- unused local variable
    "212", -- unused argument
    "421", -- shadowing local variable
    "431", -- shadowing upvalue
    "432", -- shadowing upvalue argument
  },
}
