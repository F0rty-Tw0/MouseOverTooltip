local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
Wow.Install()
local Color = require("MouseOverTooltip.Core.Color")

local function test_rgb_becomes_escape_code()
  Assert.equal(Color.Code(1, 0.5, 0), "|cffff8000")
end

local function test_wrap_closes_color()
  Assert.equal(Color.Wrap("|cffff0000", "Bob"), "|cffff0000Bob|r")
end

local function test_class_code_uses_raid_class_colors_and_caches()
  Assert.equal(Color.Class("MAGE"), Color.Code(0.25, 0.78, 0.92))
  _G.RAID_CLASS_COLORS.MAGE = { r = 0, g = 0, b = 0 }
  Assert.equal(Color.Class("MAGE"), Color.Code(0.25, 0.78, 0.92), "cached per class")
  Assert.equal(Color.Class("NOPE"), nil)
end

local function test_color_table_accepts_mixin_or_plain_table()
  Assert.equal(Color.FromTable({ r = 1, g = 1, b = 1 }), "|cffffffff")
  Assert.equal(Color.FromTable(nil), nil)
end

local function test_difficulty_prefers_retail_content_difficulty()
  _G.C_PlayerInfo = {
    GetContentDifficultyCreatureForPlayer = function()
      return 3
    end,
  }
  _G.GetDifficultyColor = function(difficulty)
    return difficulty == 3 and { r = 1, g = 0, b = 0 } or nil
  end
  Assert.equal(Color.Difficulty("mouseover", 80), "|cffff0000")
  _G.C_PlayerInfo, _G.GetDifficultyColor = nil, nil
end

local function test_difficulty_falls_back_to_creature_level_color()
  _G.GetCreatureDifficultyColor = function(level)
    return level == 60 and { r = 0, g = 1, b = 0 } or nil
  end
  Assert.equal(Color.Difficulty("mouseover", 60), "|cff00ff00")
  Assert.equal(Color.Difficulty("mouseover", -1), Color.RED, "skull level is always red")
  _G.GetCreatureDifficultyColor = nil
  Assert.equal(Color.Difficulty("mouseover", 60), Color.WHITE)
end

return function()
  test_rgb_becomes_escape_code()
  test_wrap_closes_color()
  test_class_code_uses_raid_class_colors_and_caches()
  test_color_table_accepts_mixin_or_plain_table()
  test_difficulty_prefers_retail_content_difficulty()
  test_difficulty_falls_back_to_creature_level_color()
end
