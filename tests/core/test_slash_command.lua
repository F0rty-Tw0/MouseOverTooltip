local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
Wow.Install()
_G.SlashCmdList = {}
local SlashCommand = require("MouseOverTooltip.Core.SlashCommand")

local function test_mot_opens_settings()
  local opened = 0
  SlashCommand.Register(function()
    opened = opened + 1
  end)
  Assert.equal(_G.SLASH_MOUSEOVERTOOLTIP1, "/mot")
  _G.SlashCmdList.MOUSEOVERTOOLTIP("")
  Assert.equal(opened, 1)
end

return function()
  test_mot_opens_settings()
end
