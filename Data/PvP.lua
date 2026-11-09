local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")
local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local ARENA_BRACKETS = { "2v2", "3v3" }
local TABLE_BRACKETS = {
  { "GetInspectRatedSoloShuffleData", "Solo Shuffle" },
  { "GetInspectRatedBGBlitzData", "Blitz" },
  { "GetInspectRatedBGData", "Rated BG" },
}

-- Reads the inspected player's best rated bracket (same calls as Blizzard's
-- InspectPVPFrame). On Retail INSPECT_HONOR_UPDATE fires just before
-- INSPECT_READY (in-game trace, 12.x); non-zero ratings at INSPECT_READY
-- not yet observed.
local PvP = {}

local best, bestBracket

local function consider(rating, bracket)
  rating = Secret.Clean(rating)
  if type(rating) == "number" and rating > best then
    best, bestBracket = rating, bracket
  end
end

-- Returns rating, bracket name — or nil when the player has no rating.
function PvP.Read()
  best, bestBracket = 0, nil
  for index, bracket in ipairs(ARENA_BRACKETS) do
    consider((_G.GetInspectArenaData(index)), bracket)
  end
  local paperDoll = _G.C_PaperDollInfo or {}
  for _, source in ipairs(TABLE_BRACKETS) do
    local read = paperDoll[source[1]]
    local data = read and read()
    if data then
      consider(data.rating, source[2])
    end
  end
  if not bestBracket then
    return nil
  end
  return best, Localization.Text(bestBracket)
end

ns.PvP = PvP
return PvP
