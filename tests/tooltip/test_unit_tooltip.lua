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
_G.C_PaperDollInfo = {
  GetInspectItemLevel = function()
    return 639
  end,
}

local SavedState = require("MouseOverTooltip.Settings.SavedState")
local InspectCache = require("MouseOverTooltip.Data.InspectCache")
local UnitTooltip = require("MouseOverTooltip.Tooltip.UnitTooltip")

local db = SavedState.Initialize(nil)
InspectCache.Configure({ onReady = UnitTooltip.Refresh })
UnitTooltip.Install(db)

local function hoverBob()
  W.units = {
    player = { name = "Me", guid = "Player-me", isPlayer = true },
    mouseover = { name = "Bob", guid = "Player-1", isPlayer = true, className = "Mage", classFile = "MAGE", race = "Human", level = 80 },
  }
  W.SetTooltipLines("mouseover", { "Bob", "Level 80 Human Mage (Player)" })
  postCalls[2](W.tooltip)
end

local function test_retail_uses_tooltip_data_post_calls()
  Assert.equal(type(postCalls[2]), "function")
  Assert.equal(type(postCalls[0]), "function")
end

local function test_unit_post_call_styles_player()
  hoverBob()
  Assert.equal(W.LineText(1), "|cff40c7ebBob|r")
end

local function test_other_tooltips_are_ignored()
  W.units = { mouseover = { name = "Bob", guid = "Player-1", isPlayer = true } }
  W.SetTooltipLines("mouseover", { "Bob" })
  postCalls[2]({})
  Assert.equal(W.LineText(1), "Bob")
end

local function test_refresh_after_mouse_left_does_not_cancel_fade()
  hoverBob()
  local shows = 0
  local show = W.tooltip.Show
  W.tooltip.Show = function(self)
    shows = shows + 1
    return show(self)
  end
  W.units.mouseover = nil
  postCalls[2](W.tooltip)
  W.tooltip.Show = show
  Assert.equal(shows, 0, "Show() would cancel Blizzard's fade-out")
end

local function test_inspect_result_refreshes_shown_tooltip()
  hoverBob()
  W.RunTimers()
  W.calls.RefreshData = nil
  for _, frame in ipairs(W.frames) do
    frame:FireEvent("INSPECT_READY", "Player-1")
  end
  Assert.equal(W.calls.RefreshData, 1)
end

local function test_refresh_skipped_when_another_unit_is_shown()
  W.calls.RefreshData = nil
  W.units.mouseover = { name = "Amy", guid = "Player-2", isPlayer = true }
  UnitTooltip.Refresh("Player-1")
  Assert.equal(W.calls.RefreshData, nil)
end

local function test_combat_hide_hides_before_any_styling()
  db.hideWorldInCombat = true
  W.inCombat = true
  W.tooltip:SetOwner(_G.UIParent, "ANCHOR_NONE")
  hoverBob()
  Assert.equal(W.tooltip.shown, false)
  Assert.equal(W.LineText(1), "Bob")
  db.hideWorldInCombat = false
  W.inCombat = false
end

-- Mythic+ hands out the shown unit token as a secret. These reload the tooltip
-- modules so Secret sees the marker, then hover a unit whose token is secret.
local SECRET_UNIT = {}

local function installWithSecretUnit(settings)
  rawset(_G, "issecretvalue", function(v)
    return v == SECRET_UNIT
  end)
  package.loaded["Core.Secret"] = nil
  for key in pairs(package.loaded) do
    if string.find(key, "^Tooltip%.") then
      package.loaded[key] = nil
    end
  end
  require("MouseOverTooltip.Tooltip.UnitTooltip").Install(settings)
end

local function hoverSecretUnit()
  local getUnit = W.tooltip.GetUnit
  W.tooltip.GetUnit = function()
    return nil, SECRET_UNIT
  end
  postCalls[2](W.tooltip)
  W.tooltip.GetUnit = getUnit
end

local function clearSecrets()
  rawset(_G, "issecretvalue", nil)
  package.loaded["Core.Secret"] = nil
end

local function test_secret_unit_still_hides_health_bar()
  local secretDb = SavedState.Initialize(nil)
  secretDb.hideHealthBar = true
  installWithSecretUnit(secretDb)
  _G.GameTooltipStatusBar:Show()
  hoverSecretUnit()
  clearSecrets()
  Assert.equal(_G.GameTooltipStatusBar.shown, false)
end

-- The last styled token is usually "mouseover", which still names the hovered
-- unit, so a secret token must not wipe the health text.
local function test_secret_unit_keeps_health_text()
  local secretDb = SavedState.Initialize(nil)
  secretDb.healthText = true
  installWithSecretUnit(secretDb)
  local bar = _G.GameTooltipStatusBar
  local text = { shown = true }
  function text.SetPoint() end
  function text:SetText(value)
    self.value = value
  end
  function text:Show()
    self.shown = true
  end
  function text:Hide()
    self.shown = false
  end
  local createFontString, unitHealth, unitHealthMax = bar.CreateFontString, _G.UnitHealth, _G.UnitHealthMax
  bar.CreateFontString = function()
    return text
  end
  _G.UnitHealth = function(token)
    return W.units[token] and W.units[token].health
  end
  _G.UnitHealthMax = function(token)
    return W.units[token] and W.units[token].healthMax
  end
  hoverBob()
  W.units.mouseover.health, W.units.mouseover.healthMax = 7000, 9000
  hoverSecretUnit()
  bar:Fire("OnValueChanged", 0.7)
  bar.CreateFontString, _G.UnitHealth, _G.UnitHealthMax = createFontString, unitHealth, unitHealthMax
  clearSecrets()
  Assert.equal(text.shown, true)
  Assert.equal(text.value, "7000 / 9000")
end

local function test_secret_unit_keeps_health_bar_when_setting_off()
  installWithSecretUnit(SavedState.Initialize(nil))
  _G.GameTooltipStatusBar:Show()
  hoverSecretUnit()
  clearSecrets()
  Assert.equal(_G.GameTooltipStatusBar.shown, true)
end

local function test_secret_unit_still_combat_hides()
  local secretDb = SavedState.Initialize(nil)
  secretDb.hideWorldInCombat = true
  installWithSecretUnit(secretDb)
  W.inCombat = true
  W.tooltip:SetOwner(_G.UIParent, "ANCHOR_NONE")
  W.tooltip:Show()
  hoverSecretUnit()
  W.inCombat = false
  clearSecrets()
  Assert.equal(W.tooltip.shown, false)
end

local function test_classic_hooks_tooltip_scripts()
  W = Wow.Install()
  W.scriptSupport.OnTooltipSetUnit = true
  W.scriptSupport.OnTooltipSetItem = true
  for key in pairs(package.loaded) do
    if string.find(key, "^Tooltip%.") then
      package.loaded[key] = nil
    end
  end
  local ClassicUnitTooltip = require("MouseOverTooltip.Tooltip.UnitTooltip")
  ClassicUnitTooltip.Install(SavedState.Initialize(nil))
  Assert.equal(#W.tooltip.hooks.OnTooltipSetUnit, 1)
  Assert.equal(#W.tooltip.hooks.OnTooltipSetItem, 1)
end

return function()
  test_retail_uses_tooltip_data_post_calls()
  test_unit_post_call_styles_player()
  test_other_tooltips_are_ignored()
  test_refresh_after_mouse_left_does_not_cancel_fade()
  test_inspect_result_refreshes_shown_tooltip()
  test_refresh_skipped_when_another_unit_is_shown()
  test_combat_hide_hides_before_any_styling()
  test_secret_unit_still_hides_health_bar()
  test_secret_unit_keeps_health_text()
  test_secret_unit_keeps_health_bar_when_setting_off()
  test_secret_unit_still_combat_hides()
  test_classic_hooks_tooltip_scripts()
end
