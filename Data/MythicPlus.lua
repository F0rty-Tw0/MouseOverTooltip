local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Color = ns.Color or require("MouseOverTooltip.Core.Color")
local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")
local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local floor = math.floor
local ipairs = ipairs

local MythicPlus = {}

local function bestTimedLevel(runs)
  local best = 0
  if type(runs) ~= "table" then
    return best
  end
  for _, run in ipairs(runs) do
    local level = Secret.Clean(run.bestRunLevel)
    if Secret.Clean(run.finishedSuccess) and level and level > best then
      best = level
    end
  end
  return best
end

-- "M+ 2845 • Best +14", rating in Blizzard's rarity color. nil = no line.
function MythicPlus.Line(unit)
  local summary = _G.C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
  local score = summary and Secret.Clean(summary.currentSeasonScore)
  if not score or score <= 0 then
    return nil
  end
  score = floor(score)
  local code = Color.FromTable(_G.C_ChallengeMode.GetDungeonScoreRarityColor(score)) or Color.WHITE
  local text = Color.Label(Localization.Text("M+")) .. " " .. code .. score .. "|r"
  local best = bestTimedLevel(summary.runs)
  if best > 0 then
    text = text .. " • " .. Localization.Text("Best") .. " +" .. best
  end
  return text
end

ns.MythicPlus = MythicPlus
return MythicPlus
