local Assert = require("tests.helpers.assert")
local Defaults = require("MouseOverTooltip.Settings.Defaults")

local MAX_HINT = 90

-- Every setting as shipped before the tabbed panel: { default, min, max, requires }.
-- Saved settings carry over only while these stay identical.
local SNAPSHOT = {
  colorName = { true },
  showGuild = { true },
  showLevel = { true },
  showRace = { true },
  showClass = { true },
  showFaction = { true },
  showItemLevel = { true, nil, nil, "hasItemLevel" },
  showMythicPlus = { true, nil, nil, "hasMythicPlus" },
  showSpec = { false, nil, nil, "hasSpec" },
  showPvpRating = { false, nil, nil, "hasPvpRating" },
  showRealmStatus = { false },
  showTitle = { false },
  highlightMyGuild = { false },
  showFriend = { false },
  showTarget = { false },
  showTargetedBy = { false },
  showMount = { true, nil, nil, "hasMountJournal" },
  showMountIcon = { false, nil, nil, "hasMountJournal" },
  showMountSource = { false, nil, nil, "hasMountJournal" },
  mountOnlyUncollected = { false, nil, nil, "hasMountJournal" },
  showQuest = { true },
  showClassification = { false },
  showEnemyForces = { false, nil, nil, "hasMythicPlus" },
  grayTapped = { false },
  showReaction = { false },
  showPetOwner = { false },
  followCursor = { true },
  cursorOffsetX = { 0, -100, 100 },
  cursorOffsetY = { 0, -100, 100 },
  tooltipScale = { 100, 50, 200 },
  healthText = { false },
  hideHealthBar = { false },
  showRaidIcon = { false },
  showDeadTag = { false },
  classBorder = { false },
  itemQualityBorder = { false },
  hideWorldInCombat = { false },
  hideFramesInCombat = { false },
  shiftShowsHidden = { true },
  skipInspectInCombat = { true },
  minimapButton = { true },
}

local function settings()
  local byKey, count = {}, 0
  for _, entry in ipairs(Defaults.list) do
    if entry.key then
      byKey[entry.key] = entry
      count = count + 1
    end
  end
  return byKey, count
end

local function test_first_entry_is_a_tab()
  Assert.equal(type(Defaults.list[1].tab), "string")
end

local function test_tabs_in_order()
  local names = {}
  for _, entry in ipairs(Defaults.list) do
    if entry.tab then
      names[#names + 1] = entry.tab
    end
  end
  Assert.equal(table.concat(names, ","), "General,Players,NPCs,Look,Combat")
end

local function test_every_setting_has_a_short_hint()
  for _, entry in ipairs(Defaults.list) do
    if entry.key then
      Assert.equal(type(entry.hint), "string", entry.key)
      Assert.equal(#entry.hint > 0 and #entry.hint <= MAX_HINT, true, entry.key .. " hint length " .. #entry.hint)
    end
  end
end

local function test_parent_is_earlier_checkbox_in_same_tab_and_not_a_child()
  local seen = {}
  for _, entry in ipairs(Defaults.list) do
    if entry.tab then
      seen = {}
    elseif entry.key then
      local parent = entry.parent and seen[entry.parent]
      if entry.parent then
        Assert.equal(parent ~= nil, true, entry.key .. " parent listed earlier in its tab")
        Assert.equal(parent.min, nil, entry.key .. " parent is a checkbox")
        Assert.equal(parent.parent, nil, entry.key .. " parent is not a child")
      end
      seen[entry.key] = entry
    end
  end
end

local function test_child_requires_matches_parent()
  local byKey = settings()
  for key, entry in pairs(byKey) do
    if entry.parent then
      Assert.equal(entry.requires, byKey[entry.parent].requires, key)
    end
  end
end

local function test_keys_and_defaults_unchanged()
  local byKey, count = settings()
  local expectedCount = 0
  for _ in pairs(SNAPSHOT) do
    expectedCount = expectedCount + 1
  end
  Assert.equal(count, expectedCount)
  for key, entry in pairs(byKey) do
    local expected = SNAPSHOT[key]
    Assert.equal(expected ~= nil, true, key .. " is a known setting")
    Assert.equal(entry.default, expected[1], key .. " default")
    Assert.equal(entry.min, expected[2], key .. " min")
    Assert.equal(entry.max, expected[3], key .. " max")
    Assert.equal(entry.requires, expected[4], key .. " requires")
  end
end

return function()
  test_first_entry_is_a_tab()
  test_tabs_in_order()
  test_every_setting_has_a_short_hint()
  test_parent_is_earlier_checkbox_in_same_tab_and_not_a_child()
  test_child_requires_matches_parent()
  test_keys_and_defaults_unchanged()
end
