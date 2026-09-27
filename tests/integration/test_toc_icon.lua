-- The addon list shows the TOC IconTexture; it must point at the icon file
-- bundled with the addon, or the client shows a blank square.
local Assert = require("tests.helpers.assert")

local ADDON_PREFIX = "Interface\\AddOns\\MouseOverTooltip\\"

local function tocIcon()
  for line in io.lines("MouseOverTooltip.toc") do
    local path = string.match(line, "^## IconTexture:%s*(.-)%s*$")
    if path then
      return path
    end
  end
end

local function test_toc_icon_is_bundled_tga()
  local path = tocIcon()
  Assert.equal(string.sub(path, 1, #ADDON_PREFIX), ADDON_PREFIX)
  local file = io.open(string.gsub(string.sub(path, #ADDON_PREFIX + 1), "\\", "/") .. ".tga", "rb")
  Assert.equal(file ~= nil, true, "icon file missing: " .. path)
  file:close()
end

return function()
  test_toc_icon_is_bundled_tga()
end
