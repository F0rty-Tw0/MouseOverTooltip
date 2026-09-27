local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local FlavorCompat = ns.FlavorCompat or require("MouseOverTooltip.Core.FlavorCompat")
local Lines = ns.TooltipLines or require("MouseOverTooltip.Tooltip.Lines")
local PlayerHeader = ns.PlayerHeader or require("MouseOverTooltip.Tooltip.PlayerHeader")
local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

-- Retail only (the TOC skips this file on Classic). Drops Blizzard's faction,
-- PvP and "Spec Class" lines before they are added, so the player tooltip has
-- no blank slot waiting for inspect data. ClearNoise stays as the fallback.
local LineFilter = {}

local settings
local playerData, className, pastLevel

local function onUnitData(tooltip, tooltipData)
  playerData = nil
  if tooltip ~= _G.GameTooltip or not PlayerHeader.Wanted(settings) then
    return
  end
  local guid = Secret.Clean(tooltipData.guid)
  local unit = guid and Secret.Clean(_G.UnitTokenFromGUID(guid))
  if not (unit and Secret.Clean(_G.UnitIsPlayer(unit))) then
    return
  end
  className = Secret.Clean((_G.UnitClass(unit)))
  playerData, pastLevel = tooltipData, false
end

local function onLine(tooltip, lineData)
  if not playerData or tooltip ~= _G.GameTooltip then
    return false
  end
  local info = tooltip:GetProcessingTooltipInfo()
  local text = Secret.Clean(lineData.leftText)
  if not (info and info.tooltipData == playerData and text) then
    return false
  end
  if not pastLevel then
    pastLevel = Lines.IsLevel(text)
    return false
  end
  return PlayerHeader.IsNoise(text, className)
end

function LineFilter.Install(db)
  local processor = _G.TooltipDataProcessor
  if not (FlavorCompat.isRetail and not FlavorCompat.isForever and processor and processor.AddLinePreCall) then
    return
  end
  settings = db
  processor.AddTooltipPreCall(_G.Enum.TooltipDataType.Unit, onUnitData)
  processor.AddLinePreCall(_G.Enum.TooltipDataLineType.None, onLine)
end

ns.LineFilter = LineFilter
return LineFilter
