local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

_G.FACTION_STANDING_LABEL2 = "Hostile"
_G.UNITNAME_TITLE_PET = "%s's Pet"
_G.UNITNAME_TITLE_MINION = "%s's Minion"
_G.C_PlayerInfo = { GetPlayerMythicPlusRatingSummary = function() end }
_G.C_ChallengeMode = {
  GetActiveChallengeMapID = function() end,
}

local Defaults = require("MouseOverTooltip.Settings.Defaults")
local SavedState = require("MouseOverTooltip.Settings.SavedState")
local NpcLines = require("MouseOverTooltip.Tooltip.NpcLines")

local BOAR_LINES = { "Boar", "Level 10 Beast", "Boar Hunt", " - 6/10 Boar slain", " - 2/2 Tusk collected" }

local function with(keys)
  local db = SavedState.Initialize(nil)
  for _, entry in ipairs(Defaults.list) do
    if entry.key then
      db[entry.key] = false
    end
  end
  for key, value in pairs(keys) do
    db[key] = value
  end
  return db
end

local function hover(db, unitOverrides, lines)
  local boar = { name = "Boar", guid = "Creature-0-1-2-3-555-0000AAAA", level = 10, reaction = 2, creatureType = "Beast" }
  for k, v in pairs(unitOverrides or {}) do
    boar[k] = v
  end
  W.units = { player = { name = "Me", guid = "Player-me", isPlayer = true }, mouseover = boar }
  W.calls = {}
  W.SetTooltipLines("mouseover", lines or BOAR_LINES)
  NpcLines.Apply(W.tooltip, "mouseover", boar.guid, db)
end

local function test_quest_objectives_get_left_count_and_done_color()
  hover(with({ showQuest = true }))
  Assert.equal(W.LineText(4), " - 6/10 Boar slain (4 left)")
  Assert.equal(W.LineText(5), " - 2/2 Tusk collected")
  Assert.equal(W.Line(5).color[2], 1)
end

local function test_everything_off_touches_nothing()
  hover(with({}))
  Assert.equal(W.AllText(), table.concat(BOAR_LINES, "\n"))
  Assert.equal(W.calls.UnitClassification, nil)
  Assert.equal(W.calls.UnitIsTapDenied, nil)
end

local function test_classification_rewrites_level_line()
  hover(with({ showClassification = true }), { classification = "elite", level = 80, creatureType = "Humanoid" })
  Assert.contains(W.LineText(2), "80|r")
  Assert.contains(W.LineText(2), "Elite")
  Assert.contains(W.LineText(2), "Humanoid")
end

local function test_boss_level_shows_question_marks()
  hover(with({ showClassification = true }), { classification = "worldboss", level = -1 })
  Assert.contains(W.LineText(2), "??")
  Assert.contains(W.LineText(2), "Boss")
end

local function test_reaction_text_goes_under_level()
  hover(with({ showReaction = true }))
  Assert.contains(W.LineText(2), "Level 10 Beast\n")
  Assert.contains(W.LineText(2), "Hostile")
end

local function test_tapped_npc_name_turns_gray()
  hover(with({ grayTapped = true }), { tapDenied = true })
  Assert.equal(W.Line(1).color[1], 0.5)
end

local function test_dead_tag_and_raid_icon_on_name()
  hover(with({ showDeadTag = true, showRaidIcon = true }), { dead = true, raidIcon = 8 })
  Assert.contains(W.LineText(1), "UI-RaidTargetingIcon_8")
  Assert.contains(W.LineText(1), "Boar")
  Assert.contains(W.LineText(1), "<Dead>")
end

local function test_pet_owner_line()
  hover(with({ showPetOwner = true }), { playerControlled = true }, { "Wolf", "Amy's Pet", "Level 80 Beast" })
  Assert.equal(W.LineText(2), "|cffffd100Owner:|r Amy")
end

local function test_enemy_forces_disabled_makes_no_calls()
  local calls = 0
  _G.C_ChallengeMode.GetActiveChallengeMapID = function()
    calls = calls + 1
  end
  _G.MDT = {}
  hover(with({}))
  Assert.equal(calls, 0)
  hover(with({ showEnemyForces = true }))
  Assert.equal(calls, 1)
  _G.MDT = nil
end

return function()
  test_quest_objectives_get_left_count_and_done_color()
  test_everything_off_touches_nothing()
  test_classification_rewrites_level_line()
  test_boss_level_shows_question_marks()
  test_reaction_text_goes_under_level()
  test_tapped_npc_name_turns_gray()
  test_dead_tag_and_raid_icon_on_name()
  test_pet_owner_line()
  test_enemy_forces_disabled_makes_no_calls()
end
