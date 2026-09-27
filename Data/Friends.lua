local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Color = ns.Color or require("MouseOverTooltip.Core.Color")
local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")

local match = string.match

local BNET_COLOR = "|cff82c5ff"

local Friends = {}

-- " (BattleTag)" for Battle.net friends, " (Friend)" for character friends.
function Friends.Tag(guid)
  local bnet = _G.C_BattleNet
  local account = bnet and bnet.GetAccountInfoByGUID and bnet.GetAccountInfoByGUID(guid)
  local tag = account and account.battleTag
  if type(tag) == "string" and tag ~= "" then
    return Color.Wrap(BNET_COLOR, "(" .. (match(tag, "^([^#]+)") or tag) .. ")")
  end
  local list = _G.C_FriendList
  if list and list.IsFriend and list.IsFriend(guid) then
    return Color.Wrap(Color.GREEN, "(" .. Localization.Text("Friend") .. ")")
  end
  return nil
end

ns.Friends = Friends
return Friends
