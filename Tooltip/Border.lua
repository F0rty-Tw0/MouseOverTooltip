local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local Border = {}

local RARE_COLORS = {
  rare = { r = 0.75, g = 0.75, b = 0.75 },
  rareelite = { r = 0.78, g = 0.78, b = 1 },
}

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

local function unitColor(unit)
  if Secret.Clean(_G.UnitIsPlayer(unit)) then
    local _, classFile = _G.UnitClass(unit)
    classFile = Secret.Clean(classFile)
    return classFile and _G.RAID_CLASS_COLORS[classFile]
  end
  local reaction = Secret.Clean(_G.UnitReaction(unit, "player"))
  return reaction and _G.FACTION_BAR_COLORS[reaction]
end

function Border.Unit(tooltip, unit, db)
  if not (db.classBorder or db.rareBorder) then
    return
  end
  local classification = db.rareBorder and Secret.Clean(_G.UnitClassification(unit))
  local color = classification and RARE_COLORS[classification]
  if not color and db.classBorder then
    color = unitColor(unit)
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
