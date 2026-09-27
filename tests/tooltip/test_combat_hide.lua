local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()
local CombatHide = require("MouseOverTooltip.Tooltip.CombatHide")

local function db(keys)
  local d = { hideWorldInCombat = false, hideFramesInCombat = false, shiftShowsHidden = true }
  for k, v in pairs(keys) do
    d[k] = v
  end
  return d
end

local function test_world_tooltip_hidden_in_combat()
  W.tooltip:SetOwner(_G.UIParent, "ANCHOR_NONE")
  W.inCombat = true
  Assert.equal(CombatHide.ShouldHide(W.tooltip, db({ hideWorldInCombat = true })), true)
  Assert.equal(CombatHide.ShouldHide(W.tooltip, db({ hideFramesInCombat = true })), false)
end

local function test_unit_frame_tooltip_hidden_in_combat()
  W.tooltip:SetOwner({}, "ANCHOR_NONE")
  W.inCombat = true
  Assert.equal(CombatHide.ShouldHide(W.tooltip, db({ hideFramesInCombat = true })), true)
  Assert.equal(CombatHide.ShouldHide(W.tooltip, db({ hideWorldInCombat = true })), false)
end

local function test_out_of_combat_never_hides()
  W.tooltip:SetOwner(_G.UIParent, "ANCHOR_NONE")
  W.inCombat = false
  Assert.equal(CombatHide.ShouldHide(W.tooltip, db({ hideWorldInCombat = true })), false)
end

local function test_shift_shows_hidden_tooltip_only_when_enabled()
  W.tooltip:SetOwner(_G.UIParent, "ANCHOR_NONE")
  W.inCombat = true
  W.shiftDown = true
  Assert.equal(CombatHide.ShouldHide(W.tooltip, db({ hideWorldInCombat = true })), false)
  Assert.equal(CombatHide.ShouldHide(W.tooltip, db({ hideWorldInCombat = true, shiftShowsHidden = false })), true)
  W.shiftDown = false
end

local function test_both_hides_off_calls_no_api()
  W.calls = {}
  Assert.equal(CombatHide.ShouldHide(W.tooltip, db({})), false)
  Assert.equal(W.calls.InCombatLockdown, nil)
end

return function()
  test_world_tooltip_hidden_in_combat()
  test_unit_frame_tooltip_hidden_in_combat()
  test_out_of_combat_never_hides()
  test_shift_shows_hidden_tooltip_only_when_enabled()
  test_both_hides_off_calls_no_api()
end
