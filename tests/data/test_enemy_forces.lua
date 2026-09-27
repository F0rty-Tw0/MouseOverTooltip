local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
Wow.Install()

local activeMap = 501
_G.C_ChallengeMode = {
  GetActiveChallengeMapID = function()
    return activeMap
  end,
}
_G.MDT = {
  mapInfo = { [7] = { mapID = 501 } },
  dungeonEnemies = { [7] = { { id = 12345, count = 4 }, { id = 999, count = 0 } } },
  dungeonTotalCount = { [7] = { normal = 300 } },
}
local EnemyForces = require("MouseOverTooltip.Data.EnemyForces")

local GUID = "Creature-0-1-2-3-12345-0000ABCDEF"

local function test_forces_line_shows_count_and_percent()
  Assert.equal(EnemyForces.Line(GUID), "Forces: 4 (1.3%)")
end

local function test_no_line_outside_keystone()
  activeMap = nil
  Assert.equal(EnemyForces.Line(GUID), nil)
  activeMap = 501
end

local function test_no_line_without_mdt()
  local mdt = _G.MDT
  _G.MDT = nil
  Assert.equal(EnemyForces.Line(GUID), nil)
  _G.MDT = mdt
end

local function test_zero_count_mob_has_no_line()
  Assert.equal(EnemyForces.Line("Creature-0-1-2-3-999-0000ABCDEF"), nil)
end

return function()
  test_forces_line_shows_count_and_percent()
  test_no_line_outside_keystone()
  test_no_line_without_mdt()
  test_zero_count_mob_has_no_line()
end
