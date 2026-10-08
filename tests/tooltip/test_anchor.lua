local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

-- A secret width is a table: arithmetic on it throws, like the real thing.
local SECRET = {}
rawset(_G, "issecretvalue", function(value)
  return value == SECRET
end)

local blizzardAnchors = 0
_G.GameTooltip_SetDefaultAnchor = function(tooltip, parent)
  blizzardAnchors = blizzardAnchors + 1
  tooltip:SetOwner(parent, "ANCHOR_NONE")
end
local Anchor = require("MouseOverTooltip.Tooltip.Anchor")

local function anchorWith(db)
  Anchor.Install(db)
  _G.GameTooltip_SetDefaultAnchor(W.tooltip, _G.UIParent)
  return W.tooltip
end

local function test_default_anchor_follows_cursor_when_enabled()
  local tip = anchorWith({ followCursor = true, cursorOffsetX = 0, cursorOffsetY = 0 })
  Assert.equal(blizzardAnchors, 1, "Blizzard anchor still runs")
  Assert.equal(tip.anchor, "ANCHOR_CURSOR")
  Assert.equal(tip.owner, _G.UIParent)
  Assert.equal(tip.hooks.OnSizeChanged, nil, "no resize hook until an offset is set")
end

local function test_setting_off_keeps_blizzard_anchor()
  local tip = anchorWith({ followCursor = false, cursorOffsetX = 0, cursorOffsetY = 0 })
  Assert.equal(tip.anchor, "ANCHOR_NONE")
end

-- ANCHOR_CURSOR puts the tooltip's bottom-center on the cursor; the right
-- anchor must start from the same spot, so x is shifted by half the width.
local function test_offsets_move_from_centered_spot()
  W.tooltip.width = 200
  local tip = anchorWith({ followCursor = true, cursorOffsetX = 20, cursorOffsetY = -10 })
  Assert.equal(tip.anchor, "ANCHOR_CURSOR_RIGHT")
  Assert.equal(tip.offsetX, -80)
  Assert.equal(tip.offsetY, -10)
end

local function test_one_axis_offset_keeps_horizontal_center()
  W.tooltip.width = 100
  local tip = anchorWith({ followCursor = true, cursorOffsetX = 0, cursorOffsetY = 5 })
  Assert.equal(tip.anchor, "ANCHOR_CURSOR_RIGHT")
  Assert.equal(tip.offsetX, -50)
  Assert.equal(tip.offsetY, 5)
end

local function test_resize_recenters_offset_tooltip()
  W.tooltip.width = 100
  local tip = anchorWith({ followCursor = true, cursorOffsetX = 20, cursorOffsetY = 0 })
  tip.width = 300
  tip:Fire("OnSizeChanged", 300, 50)
  Assert.equal(tip.offsetX, -130)
end

local function test_resize_leaves_other_owners_alone()
  W.tooltip.width = 100
  local tip = anchorWith({ followCursor = true, cursorOffsetX = 20, cursorOffsetY = 0 })
  tip:SetOwner({}, "ANCHOR_CURSOR_RIGHT", 5, 5)
  tip.width = 300
  tip:Fire("OnSizeChanged", 300, 50)
  Assert.equal(tip.offsetX, 5)
end

-- Other addons (e.g. Plumber) anchor GameTooltip to UIParent with the same
-- anchor type and their own offsets; a resize must not overwrite them.
local function test_same_owner_new_anchor_is_left_alone()
  W.tooltip.width = 100
  local tip = anchorWith({ followCursor = true, cursorOffsetX = 20, cursorOffsetY = 0 })
  tip:SetOwner(_G.UIParent, "ANCHOR_CURSOR_RIGHT", 4, 8)
  tip.width = 300
  tip:Fire("OnSizeChanged", 300, 50)
  Assert.equal(tip.offsetX, 4)
  Assert.equal(tip.offsetY, 8)
end

local function test_resize_after_follow_off_leaves_blizzard_anchor()
  W.tooltip.width = 100
  anchorWith({ followCursor = true, cursorOffsetX = 20, cursorOffsetY = 0 })
  local tip = anchorWith({ followCursor = false, cursorOffsetX = 20, cursorOffsetY = 0 })
  tip:Fire("OnSizeChanged", 300, 50)
  Assert.equal(tip.anchor, "ANCHOR_NONE")
  Assert.equal(tip.offsetX, nil)
end

local function test_resize_hook_installed_once()
  local db = { followCursor = true, cursorOffsetX = 20, cursorOffsetY = 0 }
  anchorWith(db)
  local tip = anchorWith(db)
  Assert.equal(#tip.hooks.OnSizeChanged, 1)
end

local function test_secret_width_falls_back_to_centered_anchor()
  W.tooltip.width = SECRET
  local tip = anchorWith({ followCursor = true, cursorOffsetX = 20, cursorOffsetY = 0 })
  Assert.equal(tip.anchor, "ANCHOR_CURSOR")
end

local function test_secret_width_on_resize_keeps_last_offset()
  W.tooltip.width = 100
  local tip = anchorWith({ followCursor = true, cursorOffsetX = 20, cursorOffsetY = 0 })
  tip.width = SECRET
  tip:Fire("OnSizeChanged", SECRET, 50)
  Assert.equal(tip.offsetX, -30)
end

local function test_follow_off_ignores_offsets()
  local tip = anchorWith({ followCursor = false, cursorOffsetX = 20, cursorOffsetY = 0 })
  Assert.equal(tip.anchor, "ANCHOR_NONE")
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

-- Nameplates are forbidden in instances; passing one to SetOwner from addon
-- code throws "Attempt to access forbidden object".
local function test_forbidden_parent_keeps_blizzard_anchor()
  local forbidden = {
    IsForbidden = function()
      return true
    end,
  }
  Anchor.Install({ followCursor = true, cursorOffsetX = 20, cursorOffsetY = 0 })
  _G.GameTooltip_SetDefaultAnchor(W.tooltip, forbidden)
  Assert.equal(W.tooltip.anchor, "ANCHOR_NONE")
end

-- Every real frame has IsForbidden; a normal one must still follow the cursor.
local function test_non_forbidden_parent_follows_cursor()
  local frame = {
    IsForbidden = function()
      return false
    end,
  }
  Anchor.Install({ followCursor = true, cursorOffsetX = 0, cursorOffsetY = 0 })
  _G.GameTooltip_SetDefaultAnchor(W.tooltip, frame)
  Assert.equal(W.tooltip.anchor, "ANCHOR_CURSOR")
end

local function test_no_on_update_script_is_ever_set()
  for _, frame in ipairs(W.frames) do
    Assert.equal(frame.scripts.OnUpdate, nil)
  end
end

return function()
  test_default_anchor_follows_cursor_when_enabled()
  test_setting_off_keeps_blizzard_anchor()
  test_offsets_move_from_centered_spot()
  test_one_axis_offset_keeps_horizontal_center()
  test_resize_recenters_offset_tooltip()
  test_resize_leaves_other_owners_alone()
  test_same_owner_new_anchor_is_left_alone()
  test_resize_after_follow_off_leaves_blizzard_anchor()
  test_resize_hook_installed_once()
  test_secret_width_falls_back_to_centered_anchor()
  test_secret_width_on_resize_keeps_last_offset()
  test_follow_off_ignores_offsets()
  test_other_tooltips_are_left_alone()
  test_forbidden_parent_keeps_blizzard_anchor()
  test_non_forbidden_parent_follows_cursor()
  test_no_on_update_script_is_ever_set()
end
