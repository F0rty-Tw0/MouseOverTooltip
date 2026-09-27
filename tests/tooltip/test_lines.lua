local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()
local Lines = require("MouseOverTooltip.Tooltip.Lines")

local function test_level_line_found_after_guild()
  W.SetTooltipLines("mouseover", { "Bob", "<Guild>", "Level 80 Human Mage (Player)", "Alliance" })
  Assert.equal(Lines.FindLevel(W.tooltip:NumLines()), 3)
end

local function test_missing_level_line_is_nil()
  W.SetTooltipLines("mouseover", { "Bob", "Something" })
  Assert.equal(Lines.FindLevel(W.tooltip:NumLines()), nil)
end

local function test_secret_line_text_reads_as_nil()
  W.SetTooltipLines("mouseover", { "Bob" })
  local marker = {}
  W.Line(1).text = marker
  rawset(_G, "issecretvalue", function(v)
    return v == marker
  end)
  package.loaded["Core.Secret"] = nil
  package.loaded["Tooltip.Lines"] = nil
  local SecretLines = require("MouseOverTooltip.Tooltip.Lines")
  Assert.equal(SecretLines.Text(1), nil)
  rawset(_G, "issecretvalue", nil)
end

return function()
  test_level_line_found_after_guild()
  test_missing_level_line_is_nil()
  test_secret_line_text_reads_as_nil()
end
