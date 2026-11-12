local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

local HINT = "<Right click for Frame Settings>"
_G.UNIT_POPUP_RIGHT_CLICK = HINT

-- Mirrors Blizzard's UnitFrame_UpdateTooltip: when SetUnit succeeds it adds a
-- blank line and the hint, then calls Show() itself, before our post-hook runs.
-- hideOnSetUnit stands in for our SetUnit post-hook hiding the tooltip;
-- setUnitFails for a SetUnit that returns false (Blizzard then adds nothing).
local blizzardLines = { "Bob", "Level 80 Human Mage (Player)" }
local hideOnSetUnit = false
local setUnitFails = false
_G.UnitFrame_UpdateTooltip = function(_frame)
  if setUnitFails then
    return
  end
  W.SetTooltipLines("party1", blizzardLines)
  if hideOnSetUnit then
    W.tooltip:Hide()
  end
  W.tooltip:AddLine(" ")
  W.tooltip:AddLine(HINT)
  W.tooltip:Show()
end

local db = { blizzardWorldInCombat = false, blizzardFramesInCombat = false }
local UnitFrameHint = require("MouseOverTooltip.Tooltip.UnitFrameHint")
UnitFrameHint.Install(db)

local function test_unit_frame_hint_is_removed()
  _G.UnitFrame_UpdateTooltip({})
  Assert.equal(W.LineText(4), nil)
  Assert.equal(W.Line(4).shown, false)
end

local function test_blank_line_above_hint_is_removed()
  _G.UnitFrame_UpdateTooltip({})
  Assert.equal(W.LineText(3), nil)
  Assert.equal(W.Line(3).shown, false)
end

local function test_unit_lines_are_kept()
  _G.UnitFrame_UpdateTooltip({})
  Assert.equal(W.LineText(1), "Bob")
  Assert.equal(W.LineText(2), "Level 80 Human Mage (Player)")
end

local function test_stock_frame_keeps_right_click_hint()
  db.blizzardFramesInCombat, W.inCombat = true, true
  W.tooltip:SetOwner({}, "ANCHOR_NONE")
  _G.UnitFrame_UpdateTooltip({})
  db.blizzardFramesInCombat, W.inCombat = false, false
  Assert.equal(W.LineText(3), " ")
  Assert.equal(W.LineText(4), HINT)
end

local function test_combat_hidden_frame_tooltip_stays_hidden()
  db.hideFramesInCombat, W.inCombat, hideOnSetUnit = true, true, true
  W.tooltip:SetOwner({}, "ANCHOR_NONE")
  _G.UnitFrame_UpdateTooltip({})
  db.hideFramesInCombat, W.inCombat, hideOnSetUnit = false, false, false
  Assert.equal(W.tooltip.shown, false)
end

local function test_hidden_tooltip_is_not_reshown()
  W.SetTooltipLines("party1", { "Bob", " ", HINT })
  W.tooltip:Hide()
  setUnitFails = true
  _G.UnitFrame_UpdateTooltip({})
  setUnitFails = false
  Assert.equal(W.tooltip.shown, false)
end

local function test_tooltip_without_hint_is_untouched()
  W.SetTooltipLines("mouseover", { "Bob", " ", "Some quest" })
  _G.UnitFrame_UpdateTooltip = function() end
  package.loaded["MouseOverTooltip.Tooltip.UnitFrameHint"] = nil
  require("MouseOverTooltip.Tooltip.UnitFrameHint").Install(db)
  _G.UnitFrame_UpdateTooltip({})
  Assert.equal(W.LineText(2), " ")
  Assert.equal(W.LineText(3), "Some quest")
end

local function test_no_hook_when_blizzard_function_missing()
  W = Wow.Install()
  _G.UnitFrame_UpdateTooltip = nil
  package.loaded["MouseOverTooltip.Tooltip.UnitFrameHint"] = nil
  require("MouseOverTooltip.Tooltip.UnitFrameHint").Install(db)
  Assert.equal(W.calls.hooksecurefunc, nil)
end

return function()
  test_unit_frame_hint_is_removed()
  test_blank_line_above_hint_is_removed()
  test_unit_lines_are_kept()
  test_stock_frame_keeps_right_click_hint()
  test_combat_hidden_frame_tooltip_stays_hidden()
  test_hidden_tooltip_is_not_reshown()
  test_tooltip_without_hint_is_untouched()
  test_no_hook_when_blizzard_function_missing()
end
