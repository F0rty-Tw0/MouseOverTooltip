local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

local canvas, opened
local category = {
  GetID = function()
    return 77
  end,
}
_G.Settings = {
  RegisterCanvasLayoutCategory = function(frame, name)
    canvas, category.name = frame, name
    return category
  end,
  RegisterAddOnCategory = function(cat)
    cat.registered = true
  end,
  OpenToCategory = function(id)
    opened = id
  end,
}
-- Vanilla-like flavor: no M+ or inspect item level APIs.
local SavedState = require("MouseOverTooltip.Settings.SavedState")
local Panel = require("MouseOverTooltip.Settings.Panel")

local db = SavedState.Initialize(nil)
local changes, counts = {}, {}
local framesBefore = #W.frames
Panel.Register(db, function(key, value)
  changes[key] = value
  counts[key] = (counts[key] or 0) + 1
end)
local framesAtRegister = #W.frames

local function boxes()
  local byLabel = {}
  for _, frame in ipairs(W.frames) do
    if frame.label then
      byLabel[frame.label:GetText()] = frame
    end
  end
  return byLabel
end

local function test_category_registered_under_addons()
  Assert.equal(category.name, "Mouseover Tooltip")
  Assert.equal(category.registered, true)
end

local function test_nothing_built_until_first_open()
  Assert.equal(framesAtRegister - framesBefore, 1, "only the empty canvas exists at login")
  canvas:Fire("OnShow")
  Assert.equal(#W.frames > framesAtRegister, true)
  local count = #W.frames
  canvas:Fire("OnShow")
  Assert.equal(#W.frames, count, "built once")
end

local function test_checkbox_shows_saved_value_and_hides_missing_apis()
  local byLabel = boxes()
  Assert.equal(byLabel["Quest progress"].checked, true)
  Assert.equal(byLabel["Target line"].checked, false)
  Assert.equal(byLabel["M+ rating + best key"], nil, "flavor lacks M+")
  Assert.equal(byLabel["Item level (inspect)"], nil, "flavor lacks inspect item level")
end

local function test_second_column_sits_right_of_first()
  local byLabel = boxes()
  local leftX = byLabel["Target line"].point[4]
  local rightX = byLabel["Quest progress"].point[4]
  Assert.equal(rightX > leftX, true)
end

local function test_click_saves_and_forwards_change()
  local box = boxes()["Minimap button"]
  box:SetChecked(false)
  box:Fire("OnClick")
  Assert.equal(db.minimapButton, false)
  Assert.equal(changes.minimapButton, false)
end

local function fireSlider(slider, value)
  slider.callback(slider.callbackOwner, value)
end

local function test_offset_sliders_built_with_one_pixel_steps()
  local byLabel = boxes()
  local x = byLabel["X"]
  Assert.equal(x.steps, 200)
  Assert.equal(x.min, -100)
  Assert.equal(x.max, 100)
  Assert.equal(x.value, 0)
  Assert.equal(x.formatters[_G.MinimalSliderWithSteppersMixin.Label.Right](12.4), "12")
  Assert.equal(byLabel["Y"].steps, 200)
end

local function test_y_slider_shares_row_right_of_x()
  local byLabel = boxes()
  Assert.equal(byLabel["Y"].point[5], byLabel["X"].point[5])
  Assert.equal(byLabel["Y"].point[4] > byLabel["X"].point[4], true)
end

local function test_slider_change_saves_and_forwards()
  fireSlider(boxes()["X"], 12.4)
  Assert.equal(db.cursorOffsetX, 12)
  Assert.equal(changes.cursorOffsetX, 12)
end

local function test_same_slider_value_does_not_forward()
  changes = {}
  fireSlider(boxes()["X"], 12)
  Assert.equal(changes.cursorOffsetX, nil)
end

local function test_slider_hover_shows_hint()
  local track = boxes()["X"].Slider
  track:Fire("OnEnter")
  Assert.equal(W.tooltip.shown, true)
  Assert.equal(W.tooltip:GetText(), "Moves the tooltip away from the cursor, in pixels. Needs 'Tooltip follows cursor'.")
  track:Fire("OnLeave")
  Assert.equal(W.tooltip.shown, false)
end

local function test_defaults_button_restores_and_refreshes()
  local x = boxes()["X"]
  x:SetValue(30)
  Assert.equal(db.cursorOffsetX, 30)
  changes, counts = {}, {}
  db.showTarget = true
  canvas:OnDefault()
  Assert.equal(db.showTarget, false)
  Assert.equal(db.minimapButton, true)
  Assert.equal(changes.minimapButton, true, "change forwarded so the button reappears")
  Assert.equal(boxes()["Minimap button"].checked, true)
  Assert.equal(db.cursorOffsetX, 0)
  Assert.equal(x.value, 0, "slider display reset")
  Assert.equal(counts.cursorOffsetX, 1, "refresh does not re-forward the reset")
end

local function test_open_goes_to_category()
  Panel.Open()
  Assert.equal(opened, 77)
end

return function()
  test_category_registered_under_addons()
  test_nothing_built_until_first_open()
  test_checkbox_shows_saved_value_and_hides_missing_apis()
  test_second_column_sits_right_of_first()
  test_click_saves_and_forwards_change()
  test_offset_sliders_built_with_one_pixel_steps()
  test_y_slider_shares_row_right_of_x()
  test_slider_change_saves_and_forwards()
  test_same_slider_value_does_not_forward()
  test_slider_hover_shows_hint()
  test_defaults_button_restores_and_refreshes()
  test_open_goes_to_category()
end
