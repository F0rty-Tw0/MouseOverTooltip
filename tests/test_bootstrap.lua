local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

_G.SlashCmdList = {}
_G.Minimap.GetWidth = function()
  return 140
end
_G.Enum = { TooltipDataType = { Item = 0, Unit = 2 } }
local postCalls = {}
_G.TooltipDataProcessor = {
  AddTooltipPostCall = function(dataType, fn)
    postCalls[dataType] = fn
  end,
}
local canvas
_G.Settings = {
  RegisterCanvasLayoutCategory = function(frame)
    canvas = frame
    return {}
  end,
  RegisterAddOnCategory = function() end,
}
function W.tooltip:SetScale(scale)
  self.scale = scale
end
_G.MouseOverTooltipDB = { showTarget = true, removed = 1 }
require("MouseOverTooltip.Bootstrap")

local function loader()
  for _, frame in ipairs(W.frames) do
    if frame.events.ADDON_LOADED then
      return frame
    end
  end
end

local function test_other_addons_loading_are_ignored()
  loader():FireEvent("ADDON_LOADED", "SomethingElse")
  Assert.equal(_G.MouseOverTooltipDB.removed, 1)
end

local function test_addon_loaded_initializes_everything_once()
  local frame = loader()
  frame:FireEvent("ADDON_LOADED", "MouseOverTooltip")
  Assert.equal(_G.MouseOverTooltipDB.showTarget, true, "saved choice kept")
  Assert.equal(_G.MouseOverTooltipDB.removed, nil, "unknown key dropped")
  Assert.equal(_G.MouseOverTooltipDB.showQuest, true, "default filled")
  Assert.equal(frame.events.ADDON_LOADED, nil, "unregistered after load")
  Assert.equal(type(postCalls[2]), "function", "unit hook installed")
  Assert.equal(_G.SLASH_MOUSEOVERTOOLTIP1, "/mot")
  Assert.equal(_G.MouseOverTooltipMinimapButton ~= nil, true, "minimap button shown by default")
  Assert.equal(W.tooltip.scale, nil, "default scale costs no call")
end

local function test_scale_slider_rescales_tooltip()
  canvas:Fire("OnShow")
  local slider
  for _, frame in ipairs(W.frames) do
    if frame.label and frame.label:GetText() == "Scale" then
      slider = frame
    end
  end
  slider.callback(slider.callbackOwner, 150)
  Assert.equal(W.tooltip.scale, 1.5)
  Assert.equal(_G.MouseOverTooltipDB.tooltipScale, 150)
end

local function test_compartment_functions_are_global()
  Assert.equal(type(_G.MouseOverTooltip_OnAddonCompartmentClick), "function")
  Assert.equal(type(_G.MouseOverTooltip_OnAddonCompartmentEnter), "function")
  Assert.equal(type(_G.MouseOverTooltip_OnAddonCompartmentLeave), "function")
end

return function()
  test_other_addons_loading_are_ignored()
  test_addon_loaded_initializes_everything_once()
  test_compartment_functions_are_global()
  test_scale_slider_rescales_tooltip()
end
