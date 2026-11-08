local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

_G.GameTooltip_SetDefaultAnchor = function(tooltip, parent)
  tooltip:SetOwner(parent, "ANCHOR_NONE")
end
local Anchor = require("MouseOverTooltip.Tooltip.Anchor")

local BLIZZARD_ANCHOR, CURSOR_ANCHOR = "ANCHOR_NONE", "ANCHOR_CURSOR"

-- Sets the default anchor in combat with the given Blizzard options.
local function anchorInCombat(parent, keys)
  local db = {
    followCursor = true,
    cursorOffsetX = 0,
    cursorOffsetY = 0,
    blizzardWorldInCombat = false,
    blizzardFramesInCombat = false,
  }
  for key, value in pairs(keys) do
    db[key] = value
  end
  Anchor.Install(db)
  W.inCombat = true
  _G.GameTooltip_SetDefaultAnchor(W.tooltip, parent)
  W.inCombat = false
  return W.tooltip.anchor
end

local function test_stock_world_unit_keeps_blizzard_anchor()
  W.units = { mouseover = { name = "Bob" } }
  Assert.equal(anchorInCombat(_G.UIParent, { blizzardWorldInCombat = true }), BLIZZARD_ANCHOR)
end

-- Herbs and chests are default-anchored to UIParent with no mouseover unit.
local function test_world_object_keeps_cursor_anchor()
  W.units = {}
  Assert.equal(anchorInCombat(_G.UIParent, { blizzardWorldInCombat = true }), CURSOR_ANCHOR)
end

local function test_stock_unit_frame_keeps_blizzard_anchor()
  Assert.equal(anchorInCombat({ unit = "party1" }, { blizzardFramesInCombat = true }), BLIZZARD_ANCHOR)
  local secureFrame = {
    GetAttribute = function(_self, name)
      return name == "unit" and "raid3" or nil
    end,
  }
  Assert.equal(anchorInCombat(secureFrame, { blizzardFramesInCombat = true }), BLIZZARD_ANCHOR)
end

-- Action buttons own spell tooltips; they keep the user's anchor.
local function test_action_button_keeps_cursor_anchor()
  Assert.equal(anchorInCombat({}, { blizzardFramesInCombat = true }), CURSOR_ANCHOR)
end

local function test_frames_option_ignores_world_tooltips()
  W.units = { mouseover = { name = "Bob" } }
  Assert.equal(anchorInCombat(_G.UIParent, { blizzardFramesInCombat = true }), CURSOR_ANCHOR)
end

local function test_both_off_calls_no_unit_api()
  W.units = { mouseover = { name = "Bob" } }
  W.calls = {}
  Assert.equal(anchorInCombat(_G.UIParent, {}), CURSOR_ANCHOR)
  Assert.equal(W.calls.UnitExists, nil)
  Assert.equal(W.calls.InCombatLockdown, nil)
end

return function()
  test_stock_world_unit_keeps_blizzard_anchor()
  test_world_object_keeps_cursor_anchor()
  test_stock_unit_frame_keeps_blizzard_anchor()
  test_action_button_keeps_cursor_anchor()
  test_frames_option_ignores_world_tooltips()
  test_both_off_calls_no_unit_api()
end
