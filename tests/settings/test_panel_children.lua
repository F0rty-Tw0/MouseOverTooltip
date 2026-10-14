local Assert = require("tests.helpers.assert")
local PanelHelper = require("tests.helpers.panel")

local OFFSET_HINT = "Moves the tooltip away from the cursor, in pixels. Needs 'Tooltip follows cursor'."

local ctx = PanelHelper.Setup({ mountJournal = true })
local W, db, canvas = ctx.W, ctx.db, ctx.canvas
local boxes, clickTab, uncheck = ctx.boxes, ctx.clickTab, ctx.uncheck
canvas:Fire("OnShow")

-- Must run before the first Players click: it needs that tab unbuilt.
local function test_unbuilt_tab_builds_with_children_disabled()
  db.showMount = false
  clickTab("Players")
  local icon = boxes()["Icon"]
  Assert.equal(icon.enabled, false)
  Assert.equal(icon.label.font, "GameFontDisable")
  db.showMount = true
  canvas:Fire("OnShow")
end

-- NPCs is never clicked elsewhere here, so this click is its first build.
local function test_unbuilt_tab_builds_with_saved_value()
  db.showReaction = true
  clickTab("NPCs")
  Assert.equal(boxes()["Reaction text"].checked, true)
  db.showReaction = false
  canvas:Fire("OnShow")
end

local function test_child_rows_indented_under_parent()
  clickTab("Players")
  local byLabel = boxes()
  Assert.equal(byLabel["Icon"].point[4] > byLabel["Mount + collected state"].point[4], true)
end

local function test_mount_children_follow_parent()
  clickTab("Players")
  db.showMountIcon = true
  local icon = boxes()["Icon"]
  Assert.equal(icon.enabled, true)
  uncheck(boxes()["Mount + collected state"])
  Assert.equal(icon.enabled, false)
  Assert.equal(icon.label.font, "GameFontDisable")
  Assert.equal(db.showMountIcon, true, "child value untouched")
  local parent = boxes()["Mount + collected state"]
  parent:SetChecked(true)
  parent:Fire("OnClick")
  Assert.equal(icon.enabled, true)
end

local function test_offset_sliders_disable_with_follow_cursor()
  clickTab("General")
  uncheck(boxes()["Tooltip follows cursor"])
  Assert.equal(boxes()["X"].enabled, false)
  Assert.equal(boxes()["Y"].enabled, false)
end

local function test_defaults_reenables_children()
  canvas:OnDefault()
  Assert.equal(boxes()["X"].enabled, true)
  Assert.equal(boxes()["X"].label.font, "GameFontHighlight")
end

local function test_disabled_child_hover_still_shows_hint()
  uncheck(boxes()["Tooltip follows cursor"])
  local track = boxes()["X"].Slider
  track:Fire("OnEnter")
  Assert.equal(W.tooltip:GetText(), OFFSET_HINT)
  track:Fire("OnLeave")
  canvas:OnDefault()
end

return function()
  test_unbuilt_tab_builds_with_children_disabled()
  test_unbuilt_tab_builds_with_saved_value()
  test_child_rows_indented_under_parent()
  test_mount_children_follow_parent()
  test_offset_sliders_disable_with_follow_cursor()
  test_defaults_reenables_children()
  test_disabled_child_hover_still_shows_hint()
end
