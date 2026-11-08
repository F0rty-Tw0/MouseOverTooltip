local Assert = require("tests.helpers.assert")
local Defaults = require("MouseOverTooltip.Settings.Defaults")
local FlavorCompat = require("MouseOverTooltip.Core.FlavorCompat")
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

local function test_offset_defaults_to_zero()
  local db = SavedState.Initialize(nil)
  Assert.equal(db.cursorOffsetX, 0)
  Assert.equal(db.cursorOffsetY, 0)
end

local function test_saved_offset_kept()
  local db = SavedState.Initialize({ cursorOffsetX = 12, cursorOffsetY = -7 })
  Assert.equal(db.cursorOffsetX, 12)
  Assert.equal(db.cursorOffsetY, -7)
end

local function test_offset_clamped()
  Assert.equal(SavedState.Initialize({ cursorOffsetX = 250 }).cursorOffsetX, 100)
  Assert.equal(SavedState.Initialize({ cursorOffsetX = -250 }).cursorOffsetX, -100)
  Assert.equal(SavedState.Initialize({ cursorOffsetX = math.huge }).cursorOffsetX, 100)
end

local function test_offset_rounded()
  Assert.equal(SavedState.Initialize({ cursorOffsetX = 12.6 }).cursorOffsetX, 13)
  Assert.equal(SavedState.Initialize({ cursorOffsetX = -0.5 }).cursorOffsetX, 0)
end

local function test_offset_bad_type_falls_back()
  Assert.equal(SavedState.Initialize({ cursorOffsetX = "12" }).cursorOffsetX, 0)
  Assert.equal(SavedState.Initialize({ cursorOffsetX = 0 / 0 }).cursorOffsetX, 0)
  Assert.equal(SavedState.Initialize({ cursorOffsetX = true }).cursorOffsetX, 0)
end

local function test_forever_new_install_gets_forever_defaults()
  FlavorCompat.isForever = true
  local db = SavedState.Initialize(nil)
  FlavorCompat.isForever = false
  Assert.equal(db.showClassification, true)
  Assert.equal(db.grayTapped, true)
  Assert.equal(db.showItemLevel, false)
  Assert.equal(db.rareBorder, true)
  Assert.equal(db.showQuest, true, "keys without foreverDefault keep default")
end

local function test_forever_saved_choice_wins()
  FlavorCompat.isForever = true
  local db = SavedState.Initialize({ showClassification = false, showItemLevel = true })
  FlavorCompat.isForever = false
  Assert.equal(db.showClassification, false)
  Assert.equal(db.showItemLevel, true)
end

local function test_forever_bad_type_falls_back_to_forever_default()
  FlavorCompat.isForever = true
  local value = SavedState.Initialize({ showItemLevel = "x" }).showItemLevel
  FlavorCompat.isForever = false
  Assert.equal(value, false)
end

return function()
  test_forever_new_install_gets_forever_defaults()
  test_forever_saved_choice_wins()
  test_forever_bad_type_falls_back_to_forever_default()
  test_new_install_gets_every_default()
  test_saved_choices_survive_initialize()
  test_spec_defaults_for_key_settings()
  test_unknown_saved_keys_are_dropped()
  test_offset_defaults_to_zero()
  test_saved_offset_kept()
  test_offset_clamped()
  test_offset_rounded()
  test_offset_bad_type_falls_back()
end
