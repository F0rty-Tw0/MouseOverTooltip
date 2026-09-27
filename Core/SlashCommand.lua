local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local SlashCommand = {}

function SlashCommand.Register(openSettings)
  _G.SLASH_MOUSEOVERTOOLTIP1 = "/mot"
  _G.SlashCmdList["MOUSEOVERTOOLTIP"] = function()
    openSettings()
  end
end

ns.SlashCommand = SlashCommand
return SlashCommand
