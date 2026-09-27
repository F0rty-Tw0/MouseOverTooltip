local Assert = require("tests.helpers.assert")
local Localization = require("MouseOverTooltip.Core.Localization")

local function test_english_text_is_its_own_key()
  Assert.equal(Localization.Text("Targeted by"), "Targeted by")
end

local function test_catalog_entry_replaces_english_text()
  Localization.catalog["Targeted by"] = "Anvisiert von"
  Assert.equal(Localization.Text("Targeted by"), "Anvisiert von")
  Localization.catalog["Targeted by"] = nil
end

return function()
  test_english_text_is_its_own_key()
  test_catalog_entry_replaces_english_text()
end
