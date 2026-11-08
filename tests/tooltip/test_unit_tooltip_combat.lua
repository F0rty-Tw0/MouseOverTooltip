local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

local postCalls = {}
_G.Enum = { TooltipDataType = { Item = 0, Unit = 2 } }
_G.TooltipDataProcessor = {
  AddTooltipPostCall = function(dataType, fn)
    postCalls[dataType] = fn
  end,
}
_G.UnitHealth = function(token)
  return W.units[token] and W.units[token].health
end
_G.UnitHealthMax = function(token)
  return W.units[token] and W.units[token].healthMax
end

local SavedState = require("MouseOverTooltip.Settings.SavedState")
local UnitTooltip = require("MouseOverTooltip.Tooltip.UnitTooltip")

local db = SavedState.Initialize(nil)
UnitTooltip.Install(db)

local BLIZZARD_NAME = "Bob"
local CUSTOM_NAME = "|cff40c7ebBob|r"

local function hoverBob()
  W.units = {
    player = { name = "Me", guid = "Player-me", isPlayer = true },
    mouseover = {
      name = "Bob",
      guid = "Player-1",
      isPlayer = true,
      className = "Mage",
      classFile = "MAGE",
      race = "Human",
      level = 80,
      health = 7000,
      healthMax = 9000,
    },
  }
  W.SetTooltipLines("mouseover", { "Bob", "Level 80 Human Mage (Player)" })
  postCalls[2](W.tooltip)
end

-- Hovers Bob in combat as a world unit and counts our Show() calls.
local function hoverInCombat(keys)
  for key, value in pairs(keys) do
    db[key] = value
  end
  W.inCombat = true
  W.tooltip:SetOwner(_G.UIParent, "ANCHOR_NONE")
  local shows, show = 0, W.tooltip.Show
  W.tooltip.Show = function(self)
    shows = shows + 1
    return show(self)
  end
  hoverBob()
  W.tooltip.Show = show
  W.inCombat = false
  for key in pairs(keys) do
    db[key] = SavedState.Initialize(nil)[key]
  end
  return shows
end

local function test_stock_world_unit_skips_custom_lines()
  W.tooltip.borderColor = nil
  local shows = hoverInCombat({ blizzardWorldInCombat = true, classBorder = true })
  Assert.equal(W.LineText(1), BLIZZARD_NAME)
  Assert.equal(W.LineText(2), "Level 80 Human Mage (Player)")
  Assert.equal(W.tooltip.borderColor, nil)
  Assert.equal(shows, 0)
end

local function test_hide_beats_blizzard()
  hoverInCombat({ blizzardWorldInCombat = true, hideWorldInCombat = true, shiftShowsHidden = false })
  Assert.equal(W.tooltip.shown, false)
end

local function test_shift_reveals_stock_when_hidden()
  W.shiftDown = true
  hoverInCombat({ blizzardWorldInCombat = true, hideWorldInCombat = true, shiftShowsHidden = true })
  W.shiftDown = false
  Assert.equal(W.tooltip.shown, true)
  Assert.equal(W.LineText(1), BLIZZARD_NAME)
end

local function test_out_of_combat_custom()
  db.blizzardWorldInCombat = true
  W.tooltip:SetOwner(_G.UIParent, "ANCHOR_NONE")
  hoverBob()
  db.blizzardWorldInCombat = false
  Assert.equal(W.LineText(1), CUSTOM_NAME)
end

-- The bar's value hook outlives the custom hover; a stock hover must not let
-- it re-show the previous unit's health text.
local function test_stock_hover_hides_custom_health_text()
  local bar = _G.GameTooltipStatusBar
  local text
  local createFontString = bar.CreateFontString
  bar.CreateFontString = function(self)
    text = createFontString(self)
    return text
  end
  db.healthText = true
  hoverBob()
  bar.CreateFontString = createFontString
  Assert.equal(text.shown, true)
  hoverInCombat({ blizzardWorldInCombat = true })
  _G.GameTooltipStatusBar:Fire("OnValueChanged", 0.5)
  db.healthText = false
  Assert.equal(text.shown, false)
end

local function test_stock_unit_uses_normal_scale()
  local scale
  W.tooltip.SetScale = function(_self, value)
    scale = value
  end
  db.tooltipScale = 150
  hoverInCombat({ blizzardWorldInCombat = true })
  Assert.equal(scale, 1)
  W.tooltip:Fire("OnTooltipCleared")
  W.tooltip.SetScale, db.tooltipScale = nil, 100
  Assert.equal(scale, 1.5)
end

local SECRET_UNIT = {}

-- Hovers a unit whose token is a secret (Mythic+), in combat, as a world unit.
local function hoverSecretInCombat(keys)
  rawset(_G, "issecretvalue", function(v)
    return v == SECRET_UNIT
  end)
  package.loaded["Core.Secret"] = nil
  for key in pairs(package.loaded) do
    if string.find(key, "^Tooltip%.") then
      package.loaded[key] = nil
    end
  end
  local secretDb = SavedState.Initialize(nil)
  for key, value in pairs(keys) do
    secretDb[key] = value
  end
  require("MouseOverTooltip.Tooltip.UnitTooltip").Install(secretDb)
  W.inCombat = true
  W.tooltip:SetOwner(_G.UIParent, "ANCHOR_NONE")
  W.tooltip:Show()
  _G.GameTooltipStatusBar:Show()
  local getUnit = W.tooltip.GetUnit
  W.tooltip.GetUnit = function()
    return nil, SECRET_UNIT
  end
  postCalls[2](W.tooltip)
  W.tooltip.GetUnit = getUnit
  W.inCombat = false
  rawset(_G, "issecretvalue", nil)
  package.loaded["Core.Secret"] = nil
end

local function test_secret_unit_stock_keeps_bar()
  hoverSecretInCombat({ hideHealthBar = true, blizzardWorldInCombat = true })
  Assert.equal(_G.GameTooltipStatusBar.shown, true)
end

local function test_secret_unit_hide_beats_blizzard()
  hoverSecretInCombat({ blizzardWorldInCombat = true, hideWorldInCombat = true, shiftShowsHidden = false })
  Assert.equal(W.tooltip.shown, false)
end

return function()
  test_stock_world_unit_skips_custom_lines()
  test_hide_beats_blizzard()
  test_shift_reveals_stock_when_hidden()
  test_out_of_combat_custom()
  test_stock_hover_hides_custom_health_text()
  test_stock_unit_uses_normal_scale()
  test_secret_unit_stock_keeps_bar()
  test_secret_unit_hide_beats_blizzard()
end
