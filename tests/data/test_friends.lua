local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
Wow.Install()

local friends, accounts = {}, {}
_G.C_FriendList = {
  IsFriend = function(guid)
    return friends[guid] == true
  end,
}
_G.C_BattleNet = {
  GetAccountInfoByGUID = function(guid)
    return accounts[guid]
  end,
}
local Friends = require("MouseOverTooltip.Data.Friends")

local function test_battle_net_friend_shows_tag_without_number()
  accounts["Player-1"] = { battleTag = "Artio#2345" }
  Assert.contains(Friends.Tag("Player-1"), "(Artio)")
end

local function test_character_friend_shows_friend()
  friends["Player-2"] = true
  Assert.contains(Friends.Tag("Player-2"), "(Friend)")
end

local function test_stranger_has_no_tag()
  Assert.equal(Friends.Tag("Player-3"), nil)
end

return function()
  test_battle_net_friend_shows_tag_without_number()
  test_character_friend_shows_friend()
  test_stranger_has_no_tag()
end
