local Assert = require("tests.helpers.assert")
local PanelHelper = require("tests.helpers.panel")

local OFFSET_HINT = "Moves the tooltip away from the cursor, in pixels. Needs 'Tooltip follows cursor'."

-- Vanilla-like flavor: no M+, inspect item level or mount APIs.
local ctx = PanelHelper.Setup()
local W, db, canvas, category = ctx.W, ctx.db, ctx.canvas, ctx.category
local boxes, tabButton, clickTab = ctx.boxes, ctx.tabButton, ctx.clickTab

local function test_category_registered_under_addons()
  Assert.equal(category.name, "Mouseover Tooltip")
  Assert.equal(category.registered, true)
end

-- Regression guard: Defaults works before any tab was ever built.
local function test_defaults_before_first_open_resets()
  db.showTarget = true
  canvas:OnDefault()
  Assert.equal(db.showTarget, false)
end

local function test_nothing_built_until_first_open()
  Assert.equal(ctx.framesAtRegister - ctx.framesBefore, 1, "only the empty canvas exists at login")
  canvas:Fire("OnShow")
  Assert.equal(#W.frames > ctx.framesAtRegister, true)
  local count = #W.frames
  canvas:Fire("OnShow")
  Assert.equal(#W.frames, count, "built once")
end

local function test_first_open_builds_general_only()
  local byLabel = boxes()
  Assert.equal(byLabel["Minimap button"] ~= nil, true)
  Assert.equal(byLabel["Quest progress"], nil, "NPCs tab not built yet")
end

local function test_tab_click_builds_once()
  clickTab("NPCs")
  Assert.equal(boxes()["Quest progress"] ~= nil, true)
  local count = #W.frames
  clickTab("NPCs")
  Assert.equal(#W.frames, count, "built once")
end

local function test_tab_switch_shows_one_frame_and_locks_highlight()
  clickTab("Players")
  Assert.equal(tabButton("Players").highlightLocked, true)
  Assert.equal(tabButton("General").highlightLocked, false)
  local byLabel = boxes()
  Assert.equal(byLabel["Minimap button"].point[2].shown, false, "General frame hidden")
  Assert.equal(byLabel["Target line"].point[2].shown, true, "Players frame shown")
end

local function test_reopen_keeps_last_tab()
  canvas:Fire("OnShow")
  Assert.equal(tabButton("Players").highlightLocked, true)
end

local function test_info_column_right_of_header_column()
  local byLabel = boxes()
  Assert.equal(byLabel["Target line"].point[4] > byLabel["Class"].point[4], true)
end

local function test_checkbox_shows_saved_value_and_hides_missing_apis()
  clickTab("Players")
  clickTab("NPCs")
  local byLabel = boxes()
  Assert.equal(byLabel["Quest progress"].checked, true)
  Assert.equal(byLabel["Target line"].checked, false)
  Assert.equal(byLabel["M+ rating + best key"], nil, "flavor lacks M+")
  Assert.equal(byLabel["Item level (inspect)"], nil, "flavor lacks inspect item level")
end

local function test_click_saves_and_forwards_change()
  clickTab("General")
  local box = boxes()["Minimap button"]
  box:SetChecked(false)
  box:Fire("OnClick")
  Assert.equal(db.minimapButton, false)
  Assert.equal(ctx.changes.minimapButton, false)
end

local function fireSlider(slider, value)
  slider.callback(slider.callbackOwner, value)
end

local function test_offset_sliders_built_with_one_pixel_steps()
  clickTab("General")
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

local function test_scale_slider_uses_percent()
  local s = boxes()["Scale"]
  Assert.equal(s.min, 50)
  Assert.equal(s.max, 200)
  Assert.equal(s.steps, 150)
  Assert.equal(s.value, 100)
  Assert.equal(s.formatters[_G.MinimalSliderWithSteppersMixin.Label.Right](149.6), "150%")
end

local function test_scale_slider_clears_its_label()
  local byLabel = boxes()
  local s, x = byLabel["Scale"], byLabel["X"]
  Assert.equal(s.point[4] - s.label.point[4], 40)
  Assert.equal(x.point[4] - x.label.point[4], 14, "offset slider layout unchanged")
end

local function test_scale_slider_on_own_row_below_offsets()
  local byLabel = boxes()
  Assert.equal(byLabel["Scale"].point[5] < byLabel["X"].point[5], true)
end

local function test_slider_change_saves_and_forwards()
  fireSlider(boxes()["X"], 12.4)
  Assert.equal(db.cursorOffsetX, 12)
  Assert.equal(ctx.changes.cursorOffsetX, 12)
end

local function test_same_slider_value_does_not_forward()
  ctx.changes = {}
  fireSlider(boxes()["X"], 12)
  Assert.equal(ctx.changes.cursorOffsetX, nil)
end

local function test_slider_hover_shows_hint()
  local track = boxes()["X"].Slider
  track:Fire("OnEnter")
  Assert.equal(W.tooltip.shown, true)
  Assert.equal(W.tooltip:GetText(), OFFSET_HINT)
  track:Fire("OnLeave")
  Assert.equal(W.tooltip.shown, false)
end

local function test_defaults_button_restores_and_refreshes()
  clickTab("General")
  local x = boxes()["X"]
  x:SetValue(30)
  Assert.equal(db.cursorOffsetX, 30)
  boxes()["Scale"]:SetValue(150)
  ctx.changes, ctx.counts = {}, {}
  db.showTarget = true
  canvas:OnDefault()
  Assert.equal(db.showTarget, false)
  Assert.equal(db.minimapButton, true)
  Assert.equal(ctx.changes.minimapButton, true, "change forwarded so the button reappears")
  Assert.equal(boxes()["Minimap button"].checked, true)
  Assert.equal(db.cursorOffsetX, 0)
  Assert.equal(x.value, 0, "slider display reset")
  Assert.equal(ctx.counts.cursorOffsetX, 1, "refresh does not re-forward the reset")
  Assert.equal(db.tooltipScale, 100)
  Assert.equal(ctx.changes.tooltipScale, 100, "change forwarded so the tooltip resizes")
  Assert.equal(boxes()["Scale"].value, 100, "slider display reset")
end

local function test_open_goes_to_category()
  ctx.Panel.Open()
  Assert.equal(ctx.opened, 77)
end

return function()
  test_category_registered_under_addons()
  test_defaults_before_first_open_resets()
  test_nothing_built_until_first_open()
  test_first_open_builds_general_only()
  test_tab_click_builds_once()
  test_tab_switch_shows_one_frame_and_locks_highlight()
  test_reopen_keeps_last_tab()
  test_info_column_right_of_header_column()
  test_checkbox_shows_saved_value_and_hides_missing_apis()
  test_click_saves_and_forwards_change()
  test_offset_sliders_built_with_one_pixel_steps()
  test_y_slider_shares_row_right_of_x()
  test_scale_slider_uses_percent()
  test_scale_slider_clears_its_label()
  test_scale_slider_on_own_row_below_offsets()
  test_slider_change_saves_and_forwards()
  test_same_slider_value_does_not_forward()
  test_slider_hover_shows_hint()
  test_defaults_button_restores_and_refreshes()
  test_open_goes_to_category()
end
