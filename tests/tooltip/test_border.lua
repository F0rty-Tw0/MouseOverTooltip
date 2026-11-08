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
  Border.Unit(W.tooltip, "mouseover", { classBorder = false, rareBorder = false })
  Border.Item(W.tooltip, { itemQualityBorder = false })
  Assert.equal(W.tooltip.borderColor, nil)
  Assert.equal(W.calls.UnitIsPlayer, nil)
  Assert.equal(W.calls.UnitClassification, nil)
end

local function startFresh(unit)
  W.tooltip.borderColor = nil
  W.tooltip:Fire("OnTooltipCleared")
  W.tooltip.borderColor = nil
  W.units.mouseover = unit
end

local function test_rare_border_silver()
  startFresh({ name = "Gazz", classification = "rare", reaction = 2 })
  Border.Unit(W.tooltip, "mouseover", { rareBorder = true })
  Assert.equal(W.tooltip.borderColor[1], 0.75)
  Assert.equal(W.tooltip.borderColor[2], 0.75)
  Assert.equal(W.tooltip.borderColor[3], 0.75)
end

local function test_rare_elite_border_lilac()
  startFresh({ name = "Gazz", classification = "rareelite", reaction = 2 })
  Border.Unit(W.tooltip, "mouseover", { rareBorder = true })
  Assert.equal(W.tooltip.borderColor[1], 0.78)
  Assert.equal(W.tooltip.borderColor[2], 0.78)
  Assert.equal(W.tooltip.borderColor[3], 1)
end

local function test_rare_border_skips_elite()
  startFresh({ name = "Ogre", classification = "elite", reaction = 2 })
  Border.Unit(W.tooltip, "mouseover", { rareBorder = true })
  Assert.equal(W.tooltip.borderColor, nil)
end

local function test_rare_wins_over_reaction()
  startFresh({ name = "Gazz", classification = "rare", reaction = 2 })
  Border.Unit(W.tooltip, "mouseover", { classBorder = true, rareBorder = true })
  Assert.equal(W.tooltip.borderColor[1], 0.75)
end

local function test_class_border_still_paints_normal_npc_with_both_on()
  startFresh({ name = "Boar", classification = "normal", reaction = 2 })
  Border.Unit(W.tooltip, "mouseover", { classBorder = true, rareBorder = true })
  Assert.equal(W.tooltip.borderColor[1], 1)
  Assert.equal(W.tooltip.borderColor[2], 0)
end

local function test_secret_classification_falls_back_to_reaction()
  rawset(_G, "issecretvalue", function(v)
    return v == "rare"
  end)
  package.loaded["Core.Secret"] = nil
  package.loaded["MouseOverTooltip.Core.Secret"] = nil
  package.loaded["Tooltip.Border"] = nil
  package.loaded["MouseOverTooltip.Tooltip.Border"] = nil
  local SecretBorder = require("MouseOverTooltip.Tooltip.Border")
  startFresh({ name = "Gazz", classification = "rare", reaction = 2 })
  SecretBorder.Unit(W.tooltip, "mouseover", { classBorder = true, rareBorder = true })
  rawset(_G, "issecretvalue", nil)
  Assert.equal(W.tooltip.borderColor[1], 1)
  Assert.equal(W.tooltip.borderColor[2], 0)
end

return function()
  test_player_border_uses_class_color()
  test_npc_border_uses_reaction_color()
  test_border_resets_when_tooltip_clears()
  test_item_quality_border()
  test_disabled_borders_touch_nothing()
  test_rare_border_silver()
  test_rare_elite_border_lilac()
  test_rare_border_skips_elite()
  test_rare_wins_over_reaction()
  test_class_border_still_paints_normal_npc_with_both_on()
  test_secret_classification_falls_back_to_reaction()
end
