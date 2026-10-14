local Assert = require("tests.helpers.assert")
local PanelHelper = require("tests.helpers.panel")

-- Flavor without the mount journal: the Mount rows are hidden.
local ctx = PanelHelper.Setup()
local W = ctx.W

local function hasText(text)
  for _, frame in ipairs(W.frames) do
    if frame:GetText() == text then
      return true
    end
  end
  return false
end

local function test_no_empty_header_when_all_rows_hidden()
  ctx.canvas:Fire("OnShow")
  ctx.clickTab("Players")
  Assert.equal(hasText("Player header"), true, "header with visible rows stays")
  Assert.equal(hasText("Mount"), false, "header with no available rows is skipped")
end

return function()
  test_no_empty_header_when_all_rows_hidden()
end
