local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

local blizzardAnchors = 0
_G.GameTooltip_SetDefaultAnchor = function(tooltip, parent)
  blizzardAnchors = blizzardAnchors + 1
  tooltip:SetOwner(parent, "ANCHOR_NONE")
end
local Anchor = require("MouseOverTooltip.Tooltip.Anchor")

local function test_default_anchor_follows_cursor_when_enabled()
  local db = { followCursor = true }
  Anchor.Install(db)
  _G.GameTooltip_SetDefaultAnchor(W.tooltip, _G.UIParent)
  Assert.equal(blizzardAnchors, 1, "Blizzard anchor still runs")
  Assert.equal(W.tooltip.anchor, "ANCHOR_CURSOR")
  Assert.equal(W.tooltip.owner, _G.UIParent)
end

local function test_setting_off_keeps_blizzard_anchor()
  local db = { followCursor = false }
  Anchor.Install(db)
  _G.GameTooltip_SetDefaultAnchor(W.tooltip, _G.UIParent)
  Assert.equal(W.tooltip.anchor, "ANCHOR_NONE")
end

local function test_other_tooltips_are_left_alone()
  local other = {
    SetOwner = function(self, _owner, anchor)
      self.anchor = anchor
    end,
  }
  Anchor.Install({ followCursor = true })
  _G.GameTooltip_SetDefaultAnchor(other, _G.UIParent)
  Assert.equal(other.anchor, "ANCHOR_NONE")
end

local function test_no_on_update_script_is_ever_set()
  for _, frame in ipairs(W.frames) do
    Assert.equal(frame.scripts.OnUpdate, nil)
  end
end

return function()
  test_default_anchor_follows_cursor_when_enabled()
  test_setting_off_keeps_blizzard_anchor()
  test_other_tooltips_are_left_alone()
  test_no_on_update_script_is_ever_set()
end
