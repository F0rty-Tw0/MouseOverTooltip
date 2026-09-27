local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

-- Feature flags come from API presence, so a flavor that gains an API later
-- lights the feature up without a code change.
local FlavorCompat = {}

local MAINLINE = _G.WOW_PROJECT_MAINLINE or 1
FlavorCompat.isRetail = (_G.WOW_PROJECT_ID or MAINLINE) == MAINLINE

-- ponytail: no WOW_PROJECT_FOREVER exists; GetBuildInfo toc 16xxx is the only signal
local FOREVER_TOC_MIN = 16000
local FOREVER_TOC_MAX = 17000
local tocVersion = type(_G.GetBuildInfo) == "function" and select(4, _G.GetBuildInfo()) or nil
FlavorCompat.isForever = type(tocVersion) == "number" and tocVersion >= FOREVER_TOC_MIN and tocVersion < FOREVER_TOC_MAX

local function has(namespace, fn)
  local tbl = _G[namespace]
  return type(tbl) == "table" and type(tbl[fn]) == "function"
end

local modernRetail = FlavorCompat.isRetail and not FlavorCompat.isForever

FlavorCompat.hasMythicPlus = modernRetail and has("C_PlayerInfo", "GetPlayerMythicPlusRatingSummary")
FlavorCompat.hasItemLevel = has("C_PaperDollInfo", "GetInspectItemLevel")
-- Era/TBC expose the spec API but have no specs; Forever runs Vanilla content.
local projectId = _G.WOW_PROJECT_ID
local hasSpecs = modernRetail or (projectId ~= nil and (projectId == _G.WOW_PROJECT_MISTS_CLASSIC or projectId == _G.WOW_PROJECT_CATACLYSM_CLASSIC))
FlavorCompat.hasSpec = hasSpecs
  and (type(_G.GetInspectSpecialization) == "function" or has("C_SpecializationInfo", "GetInspectSpecialization"))
  and type(_G.GetSpecializationInfoByID) == "function"
FlavorCompat.hasPvpRating = modernRetail and type(_G.GetInspectArenaData) == "function"
FlavorCompat.hasMountJournal = has("C_MountJournal", "GetMountFromSpell")

ns.FlavorCompat = FlavorCompat
return FlavorCompat
