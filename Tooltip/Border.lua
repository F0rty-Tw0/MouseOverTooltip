local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local Border = {}

local colored = false
local resetHooked = false

local function setColor(tooltip, r, g, b)
  local slice = tooltip.NineSlice
  if slice and slice.SetBorderColor then
    slice:SetBorderColor(r, g, b)
  elseif tooltip.SetBackdropBorderColor then
    tooltip:SetBackdropBorderColor(r, g, b)
  end
end

-- The border color survives between tooltips, so restore it on clear.
local function reset(tooltip)
  if colored then
    colored = false
    local default = _G.TOOLTIP_DEFAULT_COLOR
    setColor(tooltip, default and default.r or 1, default and default.g or 1, default and default.b or 1)
  end
end

local function paint(tooltip, r, g, b)
  if not resetHooked then
    resetHooked = true
    tooltip:HookScript("OnTooltipCleared", reset)
  end
  setColor(tooltip, r, g, b)
  colored = true
end

function Border.Unit(tooltip, unit, db)
  if not db.classBorder then
    return
  end
  local color
  if Secret.Clean(_G.UnitIsPlayer(unit)) then
    local _, classFile = _G.UnitClass(unit)
    classFile = Secret.Clean(classFile)
    color = classFile and _G.RAID_CLASS_COLORS[classFile]
  else
    local reaction = Secret.Clean(_G.UnitReaction(unit, "player"))
    color = reaction and _G.FACTION_BAR_COLORS[reaction]
  end
  if color then
    paint(tooltip, color.r, color.g, color.b)
  end
end

local function itemQuality(link)
  local items = _G.C_Item
  if items and items.GetItemQualityByID then
    return items.GetItemQualityByID(link)
  end
  return select(3, _G.GetItemInfo(link))
end

function Border.Item(tooltip, db)
  if not db.itemQualityBorder then
    return
  end
  local _, link = tooltip:GetItem()
  link = Secret.Clean(link)
  local quality = link and itemQuality(link)
  if not quality then
    return
  end
  local items = _G.C_Item
  local qualityColor = items and items.GetItemQualityColor or _G.GetItemQualityColor
  local r, g, b = qualityColor(quality)
  if r then
    paint(tooltip, r, g, b)
  end
end

ns.Border = Border
return Border
