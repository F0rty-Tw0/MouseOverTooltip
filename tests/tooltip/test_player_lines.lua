local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

_G.C_PaperDollInfo = {
  GetInspectItemLevel = function()
    return 639
  end,
}
_G.GetInspectSpecialization = function()
  return 64
end
_G.GetSpecializationInfoByID = function()
  return 64, "Frost", "desc", 135846, "DAMAGER"
end
_G.GetInspectArenaData = function() end
_G.C_PlayerInfo = {
  GetPlayerMythicPlusRatingSummary = function()
    return { currentSeasonScore = 2845, runs = { { bestRunLevel = 14, finishedSuccess = true } } }
  end,
}
_G.C_ChallengeMode = {
  GetDungeonScoreRarityColor = function()
    return { r = 1, g = 0.5, b = 0 }
  end,
}
_G.C_UnitAuras = {
  GetAuraDataByIndex = function()
    return nil
  end,
}
_G.C_MountJournal = { GetMountFromSpell = function() end }

local Defaults = require("MouseOverTooltip.Settings.Defaults")
local SavedState = require("MouseOverTooltip.Settings.SavedState")
local InspectCache = require("MouseOverTooltip.Data.InspectCache")
local PlayerLines = require("MouseOverTooltip.Tooltip.PlayerLines")
InspectCache.Configure({})

local BLIZZARD_LINES = { "Bob", "<Guild>", "Level 80 Human Mage (Player)", "Frost Mage", "Alliance", "PvP" }

local function bob(overrides)
  local unit = {
    name = "Bob",
    guid = "Player-1",
    isPlayer = true,
    className = "Mage",
    classFile = "MAGE",
    race = "Human",
    level = 80,
    faction = "Alliance",
    guild = { name = "Guild", rank = "Officer" },
  }
  for k, v in pairs(overrides or {}) do
    unit[k] = v
  end
  return unit
end

local function hover(db, unitOverrides, lines)
  W.units = { player = { name = "Me", guid = "Player-me", isPlayer = true, guild = { name = "Guild", rank = "GM" } } }
  W.units.mouseover = bob(unitOverrides)
  W.calls = {}
  W.SetTooltipLines("mouseover", lines or BLIZZARD_LINES)
  PlayerLines.Apply(W.tooltip, "mouseover", W.units.mouseover.guid, db)
end

local function allOff()
  local db = SavedState.Initialize(nil)
  for _, entry in ipairs(Defaults.list) do
    if entry.key then
      db[entry.key] = false
    end
  end
  return db
end

local BASICS = { "colorName", "showGuild", "showLevel", "showRace", "showClass", "showFaction" }

-- `allBasics = true` switches on every header toggle first, so explicit keys
-- (e.g. `showGuild = false`) override it regardless of `pairs` order.
local function with(keys)
  local db = allOff()
  if keys.allBasics then
    for _, basic in ipairs(BASICS) do
      db[basic] = true
    end
  end
  for key, value in pairs(keys) do
    if key ~= "allBasics" then
      db[key] = value
    end
  end
  return db
end

local function test_basics_rewrite_name_guild_and_level_lines()
  hover(with({ allBasics = true }))
  Assert.equal(W.LineText(1), "|cff40c7ebBob|r")
  Assert.equal(W.LineText(2), "|cff8cb4ff<Guild> - Officer|r")
  Assert.equal(W.LineText(3), "|cffffffff80|r Human |cff40c7ebMage|r |cff4a54e8(Alliance)|r")
  Assert.equal(W.LineText(4), nil, "spec/class line cleared")
  Assert.equal(W.LineText(5), nil, "faction line cleared")
  Assert.equal(W.LineText(6), nil, "PvP line cleared")
end

local function test_guild_off_moves_level_line_up()
  hover(with({ allBasics = true, showGuild = false }))
  Assert.contains(W.LineText(2), "Human", "level line takes the guild slot")
  Assert.equal(W.LineText(3), nil)
  Assert.notContains(W.AllText(), "Guild")
end

local function test_race_off_drops_race_word_only()
  hover(with({ allBasics = true, showRace = false }))
  Assert.equal(W.LineText(3), "|cffffffff80|r |cff40c7ebMage|r |cff4a54e8(Alliance)|r")
  Assert.equal(W.calls.UnitRace, nil, "disabled part makes no API call")
end

local function test_level_parts_all_off_removes_level_line()
  hover(with({ colorName = true, showGuild = true }))
  Assert.equal(W.LineText(2), "|cff8cb4ff<Guild> - Officer|r")
  Assert.equal(W.LineText(3), nil)
  Assert.equal(W.calls.UnitLevel, nil)
end

local function test_name_color_off_keeps_plain_name_but_colors_class()
  hover(with({ allBasics = true, colorName = false }))
  Assert.equal(W.LineText(1), "Bob")
  Assert.contains(W.LineText(3), "|cff40c7ebMage|r")
end

local function test_new_lines_fill_cleared_blizzard_lines()
  hover(with({ allBasics = true, showMythicPlus = true }))
  Assert.contains(W.LineText(4), "M+", "first new line reuses the blanked spec line")
  Assert.equal(W.tooltip.numLines, 6, "no line appended below the gap")
end

local function test_everything_off_leaves_blizzard_lines_and_calls_nothing()
  hover(allOff())
  Assert.equal(W.AllText(), table.concat(BLIZZARD_LINES, "\n"))
  Assert.equal(W.calls.UnitRace, nil)
  Assert.equal(W.calls.GetGuildInfo, nil)
  Assert.equal(W.calls.UnitName, nil)
end

local function test_title_status_and_realm()
  hover(with({ allBasics = true, showTitle = true, showRealmStatus = true }), { pvpName = "Bob the Kingslayer", afk = true, realm = "Stormrage" })
  Assert.contains(W.LineText(1), "Bob - the Kingslayer")
  Assert.contains(W.LineText(1), "<AFK>")
  Assert.contains(W.AllText(), "Officer|r\nStormrage\n", "realm sits between guild and level")
end

local function test_realm_hidden_when_setting_off()
  hover(with({ allBasics = true }), { realm = "Stormrage" })
  Assert.notContains(W.AllText(), "Stormrage")
end

local function test_my_guild_highlight()
  hover(with({ allBasics = true, highlightMyGuild = true }))
  Assert.equal(W.LineText(2), "|cff40ff40<Guild> - Officer|r")
end

local function test_classic_era_without_guild_line_merges_guild_into_level()
  hover(with({ allBasics = true }), nil, { "Bob", "Level 60 Human Mage (Player)" })
  Assert.contains(W.LineText(2), "<Guild> - Officer|r\n")
  Assert.contains(W.LineText(2), "Human")
end

local function test_item_level_requests_inspect_then_shows_cached_line()
  local db = with({ showItemLevel = true })
  hover(db)
  Assert.contains(W.AllText(), "|cffffd100iLvl|r |cff808080...|r", "placeholder keeps the line's slot")
  W.RunTimers()
  Assert.equal(W.lastInspect, "mouseover")
  for _, frame in ipairs(W.frames) do
    frame:FireEvent("INSPECT_READY", "Player-1")
  end
  hover(db)
  Assert.contains(W.AllText(), "|cffffd100iLvl|r |cffa335ee639|r")
end

local function test_no_item_level_placeholder_when_item_level_off()
  hover(with({ showSpec = true }), { guid = "Player-spec" })
  Assert.notContains(W.AllText(), "iLvl")
end

local function test_spec_and_role_from_inspect()
  hover(with({ allBasics = true, showItemLevel = true, showSpec = true }))
  Assert.contains(W.LineText(3), "Human Frost |cff40c7ebMage|r")
  Assert.contains(W.AllText(), "|cffffd100iLvl|r |cffa335ee639|r • DPS")
end

local function test_disabled_inspect_features_never_inspect()
  hover(with({ allBasics = true }), { guid = "Player-new" })
  Assert.equal(W.calls.CanInspect, nil)
  Assert.equal(W.calls.NotifyInspect, nil)
end

local function test_mythic_plus_line_and_disabled_path()
  local calls = 0
  local original = _G.C_PlayerInfo.GetPlayerMythicPlusRatingSummary
  _G.C_PlayerInfo.GetPlayerMythicPlusRatingSummary = function(...)
    calls = calls + 1
    return original(...)
  end
  hover(with({ showMythicPlus = true }))
  Assert.contains(W.AllText(), "|cffffd100M+|r |cffff80002845|r • Best +14")
  hover(allOff())
  Assert.equal(calls, 1, "disabled M+ makes no API call")
end

local function test_disabled_mount_makes_no_aura_or_journal_calls()
  local calls = 0
  _G.C_UnitAuras.GetAuraDataByIndex = function()
    calls = calls + 1
  end
  hover(allOff())
  Assert.equal(calls, 0)
  hover(with({ showMount = true }))
  Assert.equal(calls, 1, "enabled mount scans auras")
end

local function test_mount_source_line_aligns_with_other_lines()
  local auras, journal = _G.C_UnitAuras.GetAuraDataByIndex, _G.C_MountJournal
  _G.C_UnitAuras.GetAuraDataByIndex = function(_unit, index)
    return index == 1 and { spellId = 42777 } or nil
  end
  _G.C_MountJournal = {
    GetMountFromSpell = function()
      return 7
    end,
    GetMountInfoByID = function()
      return "Swift Spectral Tiger", 42777, 132242, false, true, 0, false, false, nil, false, false
    end,
    GetMountInfoExtraByID = function()
      return 1, "desc", "|cFFFFD200Vendor:|r Lindormi"
    end,
  }
  hover(with({ showMount = true, showMountSource = true }))
  _G.C_UnitAuras.GetAuraDataByIndex, _G.C_MountJournal = auras, journal
  Assert.contains(W.AllText(), "\nVendor: Lindormi", "source line starts at the left edge")
end

local function test_target_and_targeted_by_lines()
  hover(with({ showTarget = true }))
  Assert.notContains(W.AllText(), "Target:")
  W.units.mouseovertarget = W.units.player
  W.SetTooltipLines("mouseover", BLIZZARD_LINES)
  PlayerLines.Apply(W.tooltip, "mouseover", "Player-1", with({ showTarget = true }))
  Assert.contains(W.AllText(), "Target:|r |cffff2020<<YOU>>|r")
end

local function test_raid_icon_dead_and_friend_tags_on_name()
  _G.C_FriendList = {
    IsFriend = function()
      return true
    end,
  }
  hover(with({ showRaidIcon = true, showDeadTag = true, showFriend = true }), { raidIcon = 1, dead = true })
  Assert.contains(W.LineText(1), "UI-RaidTargetingIcon_1")
  Assert.contains(W.LineText(1), "<Dead>")
  Assert.contains(W.LineText(1), "(Friend)")
end

local function test_secret_name_leaves_name_line_untouched()
  local marker = {}
  rawset(_G, "issecretvalue", function(v)
    return v == marker
  end)
  for key in pairs(package.loaded) do
    if string.find(key, "^Core%.") or string.find(key, "^Data%.") or string.find(key, "^Tooltip%.") then
      package.loaded[key] = nil
    end
  end
  local SecretPlayerLines = require("MouseOverTooltip.Tooltip.PlayerLines")
  W.units.mouseover = bob({ name = marker })
  W.SetTooltipLines("mouseover", BLIZZARD_LINES)
  SecretPlayerLines.Apply(W.tooltip, "mouseover", "Player-1", with({ allBasics = true }))
  Assert.equal(W.LineText(1), "Bob")
  rawset(_G, "issecretvalue", nil)
end

return function()
  test_basics_rewrite_name_guild_and_level_lines()
  test_guild_off_moves_level_line_up()
  test_race_off_drops_race_word_only()
  test_level_parts_all_off_removes_level_line()
  test_name_color_off_keeps_plain_name_but_colors_class()
  test_new_lines_fill_cleared_blizzard_lines()
  test_everything_off_leaves_blizzard_lines_and_calls_nothing()
  test_title_status_and_realm()
  test_realm_hidden_when_setting_off()
  test_my_guild_highlight()
  test_classic_era_without_guild_line_merges_guild_into_level()
  test_item_level_requests_inspect_then_shows_cached_line()
  test_no_item_level_placeholder_when_item_level_off()
  test_spec_and_role_from_inspect()
  test_disabled_inspect_features_never_inspect()
  test_mythic_plus_line_and_disabled_path()
  test_disabled_mount_makes_no_aura_or_journal_calls()
  test_mount_source_line_aligns_with_other_lines()
  test_target_and_targeted_by_lines()
  test_raid_icon_dead_and_friend_tags_on_name()
  test_secret_name_leaves_name_line_untouched()
end
