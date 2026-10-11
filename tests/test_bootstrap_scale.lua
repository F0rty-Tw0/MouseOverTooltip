local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

-- Own file: needs a non-default saved scale before the addon loads.
_G.SlashCmdList = {}
_G.Minimap.GetWidth = function()
  return 140
end
_G.Enum = { TooltipDataType = { Item = 0, Unit = 2 } }
_G.TooltipDataProcessor = { AddTooltipPostCall = function() end }
function W.tooltip:SetScale(scale)
  self.scale = scale
end
_G.MouseOverTooltipDB = { tooltipScale = 150 }
require("MouseOverTooltip.Bootstrap")

local function test_saved_scale_applied_at_login()
  for _, frame in ipairs(W.frames) do
    if frame.events.ADDON_LOADED then
      frame:FireEvent("ADDON_LOADED", "MouseOverTooltip")
    end
  end
  Assert.equal(W.tooltip.scale, 1.5)
end

return function()
  test_saved_scale_applied_at_login()
end
