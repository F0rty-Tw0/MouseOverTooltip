local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

local Defaults = require("MouseOverTooltip.Settings.Defaults")
local Widgets = require("MouseOverTooltip.Settings.Widgets")

local parent = _G.CreateFrame("Frame")
local db = { showLevel = true, cursorOffsetX = 0 }
local changed = {}
local onChanged = function(key, value)
  changed[key] = value
end

local sliderEntry
for _, entry in ipairs(Defaults.list) do
  if entry.key == "cursorOffsetX" then
    sliderEntry = entry
  end
end

local box = Widgets.AddCheckbox(parent, { key = "showLevel", default = true, label = "Level", hint = "Shows the level." }, 0, 0, db, onChanged)
local slider = Widgets.AddSlider(parent, sliderEntry, 0, -30, db, onChanged)

local function test_checkbox_hover_shows_hint()
  box:Fire("OnEnter")
  Assert.equal(W.tooltip:GetText(), "Shows the level.")
  Assert.equal(W.tooltip.wrap, true, "long hints wrap")
  box:Fire("OnLeave")
  Assert.equal(W.tooltip.shown, false)
end

local function test_slider_hover_shows_wrapped_hint()
  slider.Slider:Fire("OnEnter")
  Assert.equal(W.tooltip:GetText(), sliderEntry.hint)
  Assert.equal(W.tooltip.wrap, true)
  slider.Slider:Fire("OnLeave")
end

local function test_checkbox_keeps_motion_scripts_while_disabled()
  Assert.equal(box.motionWhileDisabled, true)
end

local function test_set_enabled_false_disables_and_grays_label()
  Widgets.SetEnabled(box, false)
  Assert.equal(box.enabled, false)
  Assert.equal(box.label.font, "GameFontDisable")
  Widgets.SetEnabled(box, true)
  Assert.equal(box.enabled, true)
  Assert.equal(box.label.font, "GameFontHighlight")
end

local function test_set_enabled_tolerates_missing_methods()
  Widgets.SetEnabled({ label = {} }, false)
end

local function test_checkbox_click_saves_and_forwards()
  box:SetChecked(false)
  box:Fire("OnClick")
  Assert.equal(db.showLevel, false)
  Assert.equal(changed.showLevel, false)
end

return function()
  test_checkbox_hover_shows_hint()
  test_slider_hover_shows_wrapped_hint()
  test_checkbox_keeps_motion_scripts_while_disabled()
  test_set_enabled_false_disables_and_grays_label()
  test_set_enabled_tolerates_missing_methods()
  test_checkbox_click_saves_and_forwards()
end
