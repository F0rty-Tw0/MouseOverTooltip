-- The live client exposes a global `require` that throws for unknown modules,
-- so every file's `ns.X or require(...)` fallback must never be reached:
-- each dependency has to load earlier in the TOC.
local Wow = require("tests.helpers.wow")

local function tocFiles()
  local files = {}
  for line in io.lines("MouseOverTooltip.toc") do
    if line ~= "" and string.sub(line, 1, 2) ~= "##" then
      files[#files + 1] = line
    end
  end
  return files
end

local function test_every_toc_file_loads_in_order_without_require()
  Wow.Install()
  local savedRequire = require
  _G.require = function(moduleName)
    error("Invalid import: No module with that name exists (" .. tostring(moduleName) .. ")")
  end

  local ns = {}
  local ok, err = pcall(function()
    for _, file in ipairs(tocFiles()) do
      local chunk = assert(loadfile(file))
      local loaded, loadErr = pcall(chunk, "MouseOverTooltip", ns)
      assert(loaded, file .. ": " .. tostring(loadErr))
    end
  end)

  _G.require = savedRequire
  assert(ok, tostring(err))
end

return function()
  test_every_toc_file_loads_in_order_without_require()
end
