local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Color = ns.Color or require("MouseOverTooltip.Core.Color")
local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")
local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local MAX_RAID_ICON = 8

local UnitTags = {}

local raidIcons = {}
for index = 1, MAX_RAID_ICON do
  raidIcons[index] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. index .. ":0|t "
end

function UnitTags.RaidIcon(unit)
  local index = Secret.Clean(_G.GetRaidTargetIndex(unit))
  return index and raidIcons[index]
end

-- " <Ghost>" / " <Dead>" in gray, nil when alive.
function UnitTags.Dead(unit)
  if Secret.Clean(_G.UnitIsGhost(unit)) then
    return " " .. Color.Wrap(Color.GRAY, "<" .. Localization.Text("Ghost") .. ">")
  end
  if Secret.Clean(_G.UnitIsDead(unit)) then
    return " " .. Color.Wrap(Color.GRAY, "<" .. Localization.Text("Dead") .. ">")
  end
  return nil
end

ns.UnitTags = UnitTags
return UnitTags
