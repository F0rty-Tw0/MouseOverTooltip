local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
Wow.Install()

local summary
_G.C_PlayerInfo = {
  GetPlayerMythicPlusRatingSummary = function()
    return summary
  end,
}
_G.C_ChallengeMode = {
  GetDungeonScoreRarityColor = function()
    return { r = 1, g = 0.5, b = 0 }
  end,
}
local MythicPlus = require("MouseOverTooltip.Data.MythicPlus")

local function test_mythic_line_shows_colored_rating_and_best_key()
  summary = {
    currentSeasonScore = 2845,
    runs = {
      { bestRunLevel = 12, finishedSuccess = true },
      { bestRunLevel = 16, finishedSuccess = false },
      { bestRunLevel = 14, finishedSuccess = true },
    },
  }
  Assert.equal(MythicPlus.Line("mouseover"), "|cffffd100M+|r |cffff80002845|r • Best +14")
end

local function test_no_line_without_rating()
  summary = { currentSeasonScore = 0, runs = {} }
  Assert.equal(MythicPlus.Line("mouseover"), nil)
  summary = nil
  Assert.equal(MythicPlus.Line("mouseover"), nil)
end

local function test_rating_without_timed_run_omits_best()
  summary = { currentSeasonScore = 150, runs = { { bestRunLevel = 2, finishedSuccess = false } } }
  Assert.equal(MythicPlus.Line("mouseover"), "|cffffd100M+|r |cffff8000150|r")
end

return function()
  test_mythic_line_shows_colored_rating_and_best_key()
  test_no_line_without_rating()
  test_rating_without_timed_run_omits_best()
end
