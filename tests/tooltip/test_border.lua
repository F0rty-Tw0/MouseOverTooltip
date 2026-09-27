local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

_G.TOOLTIP_DEFAULT_COLOR = { r = 1, g = 1, b = 1 }
_G.C_Item = {
  GetItemQualityByID = function()
    return 4
  end,
  GetItemQualityColor = function()
    return 0.64, 0.21, 0.93
  end,
}
local Border = require("MouseOverTooltip.Tooltip.Border")

local function test_player_border_uses_class_color()
  W.units.mouseover = { name = "Bob", isPlayer = true, classFile = "MAGE" }
  Border.Unit(W.tooltip, "mouseover", { classBorder = true })
  Assert.equal(W.tooltip.borderColor[1], 0.25)
end

local function test_npc_border_uses_reaction_color()
  W.units.mouseover = { name = "Boar", reaction = 2 }
  Border.Unit(W.tooltip, "mouseover", { classBorder = true })
  Assert.equal(W.tooltip.borderColor[1], 1)
  Assert.equal(W.tooltip.borderColor[2], 0)
end

local function test_border_resets_when_tooltip_clears()
  W.tooltip:Fire("OnTooltipCleared")
  Assert.equal(W.tooltip.borderColor[2], 1)
end

local function test_item_quality_border()
  W.tooltipItemName, W.tooltipItemLink = "Sword", "|Hitem:1|h[Sword]|h"
  Border.Item(W.tooltip, { itemQualityBorder = true })
  Assert.equal(W.tooltip.borderColor[1], 0.64)
end

local function test_disabled_borders_touch_nothing()
  W.tooltip.borderColor = nil
  W.calls = {}
  Border.Unit(W.tooltip, "mouseover", { classBorder = false })
  Border.Item(W.tooltip, { itemQualityBorder = false })
  Assert.equal(W.tooltip.borderColor, nil)
  Assert.equal(W.calls.UnitIsPlayer, nil)
end

return function()
  test_player_border_uses_class_color()
  test_npc_border_uses_reaction_color()
  test_border_resets_when_tooltip_clears()
  test_item_quality_border()
  test_disabled_borders_touch_nothing()
end
