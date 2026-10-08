local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()
local Group = require("MouseOverTooltip.Data.Group")

local boss = { name = "Boss", guid = "Creature-1", reaction = 2 }
local me = { name = "Me", guid = "Player-me", isPlayer = true, classFile = "MAGE", className = "Mage" }

local function test_target_line_shows_you_marker()
  W.units = { player = me, mouseover = boss, mouseovertarget = me }
  Assert.contains(Group.Target("mouseover"), "<<YOU>>")
end

local function test_target_line_class_colors_players()
  local amy = { name = "Amy", guid = "Player-2", isPlayer = true, classFile = "WARRIOR" }
  W.units = { player = me, mouseover = boss, mouseovertarget = amy }
  Assert.equal(Group.Target("mouseover"), "|cffc79c6eAmy|r")
end

local function test_no_target_no_line()
  W.units = { player = me, mouseover = boss }
  Assert.equal(Group.Target("mouseover"), nil)
end

local function test_targeted_by_lists_party_members_but_not_me()
  local amy = { name = "Amy", guid = "Player-2", isPlayer = true, classFile = "WARRIOR" }
  local tom = { name = "Tom", guid = "Player-3", isPlayer = true, classFile = "MAGE" }
  W.units = { player = me, mouseover = boss, party1 = amy, party1target = boss, party2 = tom, party2target = me, playertarget = boss }
  W.groupSize = 3
  Assert.equal(Group.TargetedBy("mouseover"), "|cffc79c6eAmy|r")
end

local function test_targeted_by_uses_raid_units_in_raid()
  local amy = { name = "Amy", guid = "Player-2", isPlayer = true, classFile = "WARRIOR" }
  local tom = { name = "Tom", guid = "Player-3", isPlayer = true, classFile = "MAGE" }
  W.units = { player = me, mouseover = boss, raid1 = me, raid1target = boss, raid2 = amy, raid2target = boss, raid3 = tom, raid3target = boss }
  W.groupSize = 3
  W.inRaid = true
  Assert.equal(Group.TargetedBy("mouseover"), "|cffc79c6eAmy|r, |cff40c7ebTom|r")
end

local function test_targeted_by_solo_makes_no_unit_calls()
  W.units = { player = me, mouseover = boss }
  W.groupSize = 0
  W.calls.UnitIsUnit = nil
  Assert.equal(Group.TargetedBy("mouseover"), nil)
  Assert.equal(W.calls.UnitIsUnit, nil)
end

-- Secret existence: skip the target line instead of erroring.
local function test_secret_target_existence_skips_line()
  local amy = { name = "Amy", guid = "Player-2", isPlayer = true, classFile = "WARRIOR" }
  W.units = { player = me, mouseover = boss, mouseovertarget = amy }
  local marker = {}
  local unitExists = _G.UnitExists
  rawset(_G, "issecretvalue", function(v)
    return v == marker
  end)
  rawset(_G, "UnitExists", function()
    return marker
  end)
  package.loaded["Core.Secret"] = nil
  package.loaded["Data.Group"] = nil
  local SecretGroup = require("MouseOverTooltip.Data.Group")
  Assert.equal(SecretGroup.Target("mouseover"), nil)
  rawset(_G, "UnitExists", unitExists)
  rawset(_G, "issecretvalue", nil)
  package.loaded["Core.Secret"] = nil
end

return function()
  test_target_line_shows_you_marker()
  test_target_line_class_colors_players()
  test_no_target_no_line()
  test_targeted_by_lists_party_members_but_not_me()
  test_targeted_by_uses_raid_units_in_raid()
  test_targeted_by_solo_makes_no_unit_calls()
  test_secret_target_existence_skips_line()
end
