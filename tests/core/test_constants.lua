local Assert = require("tests.helpers.assert")
local Constants = require("MouseOverTooltip.Core.Constants")

local function test_version_matches_toc()
  local tocVersion
  for line in io.lines("MouseOverTooltip.toc") do
    tocVersion = tocVersion or string.match(line, "^## Version: (%S+)")
  end
  Assert.equal(Constants.VERSION, tocVersion)
end

local function test_inspect_cache_limits_follow_spec()
  Assert.equal(Constants.INSPECT_CACHE_MAX, 100)
  Assert.equal(Constants.INSPECT_CACHE_TTL, 300)
end

return function()
  test_version_matches_toc()
  test_inspect_cache_limits_follow_spec()
end
