local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()
local UnitTags = require("MouseOverTooltip.Tooltip.UnitTags")

local function test_raid_icon_markup_uses_marker_index()
  W.units.mouseover = { name = "Bob", raidIcon = 8 }
  Assert.equal(UnitTags.RaidIcon("mouseover"), "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t ")
  W.units.mouseover.raidIcon = nil
  Assert.equal(UnitTags.RaidIcon("mouseover"), nil)
end

local function test_dead_and_ghost_tags()
  W.units.mouseover = { name = "Bob", dead = true }
  Assert.contains(UnitTags.Dead("mouseover"), "<Dead>")
  W.units.mouseover = { name = "Bob", ghost = true }
  Assert.contains(UnitTags.Dead("mouseover"), "<Ghost>")
  W.units.mouseover = { name = "Bob" }
  Assert.equal(UnitTags.Dead("mouseover"), nil)
end

return function()
  test_raid_icon_markup_uses_marker_index()
  test_dead_and_ghost_tags()
end
