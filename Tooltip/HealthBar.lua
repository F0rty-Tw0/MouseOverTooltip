local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local floor = math.floor
local tostring = tostring

local HealthBar = {}

local settings
local shownUnit
local text

-- AbbreviateNumbers accepts secret numbers (12.x); concatenating the result
-- is allowed, comparing it is not.
local function abbreviate(value)
  local fn = _G.AbbreviateNumbers or _G.AbbreviateLargeNumbers
  return fn and fn(value) or tostring(floor(value))
end

local function healthText(unit)
  local health, maxHealth = _G.UnitHealth(unit), _G.UnitHealthMax(unit)
  if Secret.Is(health) or Secret.Is(maxHealth) then
    if _G.AbbreviateNumbers then
      return _G.AbbreviateNumbers(health) .. " / " .. _G.AbbreviateNumbers(maxHealth)
    end
    return ""
  end
  if not health or not maxHealth or maxHealth <= 0 then
    return ""
  end
  return abbreviate(health) .. " / " .. abbreviate(maxHealth)
end

-- The bar itself only carries a 0-1 fraction, so read the unit's health.
-- Driven by OnValueChanged: updates only when health changes.
local function onValueChanged()
  if not settings.healthText or not shownUnit then
    text:Hide()
    return
  end
  text:SetText(healthText(shownUnit))
  text:Show()
end

-- For a tooltip whose unit is unknown: hides the bar, leaves the text's unit.
function HealthBar.HideBar(db)
  local bar = _G.GameTooltipStatusBar
  if bar and db.hideHealthBar then
    bar:Hide()
  end
end

function HealthBar.Apply(db, unit)
  settings, shownUnit = db, unit
  local bar = _G.GameTooltipStatusBar
  if not bar then
    return
  end
  if db.hideHealthBar then
    bar:Hide()
    return
  end
  if db.healthText and not text then
    text = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar:HookScript("OnValueChanged", onValueChanged)
  end
  if text then
    onValueChanged()
  end
end

ns.HealthBar = HealthBar
return HealthBar
