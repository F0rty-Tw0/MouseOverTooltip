local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Border = ns.Border or require("MouseOverTooltip.Tooltip.Border")
local CombatHide = ns.CombatHide or require("MouseOverTooltip.Tooltip.CombatHide")
local HealthBar = ns.HealthBar or require("MouseOverTooltip.Tooltip.HealthBar")
local NpcLines = ns.NpcLines or require("MouseOverTooltip.Tooltip.NpcLines")
local PlayerLines = ns.PlayerLines or require("MouseOverTooltip.Tooltip.PlayerLines")
local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local UnitTooltip = {}

local settings

local function shownUnit(tooltip)
  local _, unit = tooltip:GetUnit()
  return Secret.Clean(unit)
end

local function onUnit(tooltip)
  if tooltip ~= _G.GameTooltip then
    return
  end
  local unit = shownUnit(tooltip)
  if not unit then
    -- Secret in Mythic+: still hide the bar and drop the last unit's health text.
    HealthBar.Apply(settings, nil)
    return
  end
  -- Mouse already left: the tooltip is fading, and Show() would cancel the
  -- fade so it sticks to the cursor (target refreshes often in combat).
  if unit == "mouseover" and not _G.UnitExists("mouseover") then
    return
  end
  if CombatHide.ShouldHide(tooltip, settings) then
    tooltip:Hide()
    return
  end
  local guid = Secret.Clean(_G.UnitGUID(unit))
  if Secret.Clean(_G.UnitIsPlayer(unit)) then
    PlayerLines.Apply(tooltip, unit, guid, settings)
  else
    NpcLines.Apply(tooltip, unit, guid, settings)
  end
  HealthBar.Apply(settings, unit)
  Border.Unit(tooltip, unit, settings)
  tooltip:Show()
end

local function onItem(tooltip)
  if tooltip == _G.GameTooltip then
    Border.Item(tooltip, settings)
  end
end

-- Inspect data arrived: rebuild the tooltip if it still shows that player.
function UnitTooltip.Refresh(guid)
  local tooltip = _G.GameTooltip
  if not tooltip:IsShown() then
    return
  end
  local unit = shownUnit(tooltip)
  if not unit or Secret.Clean(_G.UnitGUID(unit)) ~= guid then
    return
  end
  if tooltip.RefreshData then
    tooltip:RefreshData()
  else
    tooltip:SetUnit(unit)
  end
end

-- Classic still fires OnTooltipSetUnit; Retail routes through tooltip data.
function UnitTooltip.Install(db)
  settings = db
  local tooltip = _G.GameTooltip
  if tooltip:HasScript("OnTooltipSetUnit") then
    tooltip:HookScript("OnTooltipSetUnit", onUnit)
    tooltip:HookScript("OnTooltipSetItem", onItem)
  elseif _G.TooltipDataProcessor then
    local types = _G.Enum.TooltipDataType
    _G.TooltipDataProcessor.AddTooltipPostCall(types.Unit, onUnit)
    _G.TooltipDataProcessor.AddTooltipPostCall(types.Item, onItem)
  end
end

ns.UnitTooltip = UnitTooltip
return UnitTooltip
