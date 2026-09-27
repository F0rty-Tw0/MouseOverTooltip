local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
Wow.Install()

local arena = { [1] = 1800, [2] = 1950 }
_G.GetInspectArenaData = function(index)
  return arena[index], 10, 5, 2, 1
end
_G.C_PaperDollInfo = {
  GetInspectRatedBGData = function()
    return { rating = 1500 }
  end,
  GetInspectRatedSoloShuffleData = function()
    return { rating = 2100 }
  end,
  GetInspectRatedBGBlitzData = function()
    return { rating = 0 }
  end,
}
local PvP = require("MouseOverTooltip.Data.PvP")

local function test_highest_bracket_wins()
  local rating, bracket = PvP.Read()
  Assert.equal(rating, 2100)
  Assert.equal(bracket, "Solo Shuffle")
end

local function test_arena_bracket_named()
  arena[2] = 2400
  local rating, bracket = PvP.Read()
  Assert.equal(rating, 2400)
  Assert.equal(bracket, "3v3")
end

local function test_unrated_player_returns_nil()
  arena = {}
  _G.C_PaperDollInfo = {}
  Assert.equal(PvP.Read(), nil)
end

return function()
  test_highest_bracket_wins()
  test_arena_bracket_named()
  test_unrated_player_returns_nil()
end
