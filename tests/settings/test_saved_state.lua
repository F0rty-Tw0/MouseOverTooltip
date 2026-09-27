local Assert = require("tests.helpers.assert")
local Defaults = require("MouseOverTooltip.Settings.Defaults")
local SavedState = require("MouseOverTooltip.Settings.SavedState")

local function test_new_install_gets_every_default()
  local db = SavedState.Initialize(nil)
  for _, entry in ipairs(Defaults.list) do
    if entry.key then
      Assert.equal(db[entry.key], entry.default, entry.key)
    end
  end
end

local function test_saved_choices_survive_initialize()
  local db = SavedState.Initialize({ showItemLevel = false, showTarget = true })
  Assert.equal(db.showItemLevel, false)
  Assert.equal(db.showTarget, true)
  Assert.equal(db.showMythicPlus, true)
end

local function test_spec_defaults_for_key_settings()
  local db = SavedState.Initialize(nil)
  for _, key in ipairs({ "colorName", "showGuild", "showLevel", "showRace", "showClass", "showFaction" }) do
    Assert.equal(db[key], true, key)
  end
  Assert.equal(db.showQuest, true)
  Assert.equal(db.followCursor, true)
  Assert.equal(db.shiftShowsHidden, true)
  Assert.equal(db.skipInspectInCombat, true)
  Assert.equal(db.minimapButton, true)
  Assert.equal(db.showSpec, false)
  Assert.equal(db.itemQualityBorder, false)
end

local function test_unknown_saved_keys_are_dropped()
  local db = SavedState.Initialize({ removedSetting = true })
  Assert.equal(db.removedSetting, nil)
end

return function()
  test_new_install_gets_every_default()
  test_saved_choices_survive_initialize()
  test_spec_defaults_for_key_settings()
  test_unknown_saved_keys_are_dropped()
end
