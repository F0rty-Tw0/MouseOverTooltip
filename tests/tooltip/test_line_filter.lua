local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

local UNIT_TYPE, NONE_LINE = 2, 0
local unitPreCalls, linePreCalls = {}, {}
_G.Enum = { TooltipDataType = { Unit = UNIT_TYPE }, TooltipDataLineType = { None = NONE_LINE } }
_G.TooltipDataProcessor = {
  AddTooltipPreCall = function(dataType, fn)
    unitPreCalls[dataType] = fn
  end,
  AddLinePreCall = function(lineType, fn)
    linePreCalls[lineType] = fn
  end,
}
_G.UnitTokenFromGUID = function(guid)
  for token, data in pairs(W.units) do
    if data.guid == guid then
      return token
    end
  end
  return nil
end

local FlavorCompat = require("MouseOverTooltip.Core.FlavorCompat")
local SavedState = require("MouseOverTooltip.Settings.SavedState")
local LineFilter = require("MouseOverTooltip.Tooltip.LineFilter")

local db = SavedState.Initialize(nil)
LineFilter.Install(db)

W.units = {
  mouseover = { name = "Bob", guid = "Player-1", isPlayer = true, className = "Mage", classFile = "MAGE" },
  target = { name = "Boar", guid = "Creature-1", isPlayer = false },
}

local processing
function W.tooltip:GetProcessingTooltipInfo()
  return processing
end

-- Runs Blizzard's pre-calls over `texts`; returns the lines that survive.
local function build(guid, texts, tooltip)
  tooltip = tooltip or W.tooltip
  local data = { type = UNIT_TYPE, guid = guid }
  processing = { tooltipData = data }
  unitPreCalls[UNIT_TYPE](tooltip, data)
  local kept = {}
  for _, text in ipairs(texts) do
    if not linePreCalls[NONE_LINE](tooltip, { type = NONE_LINE, leftText = text }) then
      kept[#kept + 1] = text
    end
  end
  return table.concat(kept, "|")
end

local PLAYER_LINES = { "Bob", "<Mage Guild>", "Level 80 Human Mage (Player)", "Frost Mage", "Alliance", "PvP" }

local function test_drops_faction_pvp_and_spec_lines_under_level_line()
  Assert.equal(build("Player-1", PLAYER_LINES), "Bob|<Mage Guild>|Level 80 Human Mage (Player)")
end

local function test_keeps_lines_above_level_line()
  Assert.equal(build("Player-1", { "Bob", "Frost Mage", "Level 80 Human Mage (Player)" }), "Bob|Frost Mage|Level 80 Human Mage (Player)")
end

local function test_keeps_npc_lines()
  Assert.equal(build("Creature-1", { "Boar", "Level 10 Beast", "Alliance" }), "Boar|Level 10 Beast|Alliance")
end

local function test_keeps_lines_of_other_tooltips()
  Assert.equal(build("Player-1", PLAYER_LINES, {}), table.concat(PLAYER_LINES, "|"))
end

local function test_keeps_lines_of_a_later_non_unit_tooltip()
  build("Player-1", PLAYER_LINES)
  processing = { tooltipData = { type = 0 } }
  Assert.equal(linePreCalls[NONE_LINE](W.tooltip, { type = NONE_LINE, leftText = "Classes: Mage" }), false)
end

local function test_keeps_blizzard_lines_when_header_is_off()
  for key, value in pairs(db) do
    if type(value) == "boolean" then
      db[key] = false
    end
  end
  Assert.equal(build("Player-1", PLAYER_LINES), table.concat(PLAYER_LINES, "|"))
  for key, value in pairs(SavedState.Initialize(nil)) do
    db[key] = value
  end
end

local function test_keeps_secret_text()
  _G.issecretvalue = function(value)
    return value == "Alliance"
  end
  package.loaded["Core.Secret"] = nil
  package.loaded["Tooltip.LineFilter"] = nil
  unitPreCalls, linePreCalls = {}, {}
  require("MouseOverTooltip.Tooltip.LineFilter").Install(db)
  Assert.equal(build("Player-1", PLAYER_LINES), "Bob|<Mage Guild>|Level 80 Human Mage (Player)|Alliance")
  _G.issecretvalue = nil
end

local function test_forever_registers_nothing()
  unitPreCalls, linePreCalls = {}, {}
  FlavorCompat.isForever = true
  LineFilter.Install(db)
  FlavorCompat.isForever = false
  Assert.equal(next(unitPreCalls), nil)
  Assert.equal(next(linePreCalls), nil)
end

return function()
  test_drops_faction_pvp_and_spec_lines_under_level_line()
  test_keeps_lines_above_level_line()
  test_keeps_npc_lines()
  test_keeps_lines_of_other_tooltips()
  test_keeps_lines_of_a_later_non_unit_tooltip()
  test_keeps_blizzard_lines_when_header_is_off()
  test_keeps_secret_text()
  test_forever_registers_nothing()
end
