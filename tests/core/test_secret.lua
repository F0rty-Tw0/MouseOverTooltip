local Assert = require("tests.helpers.assert")

local function load(checker)
  rawset(_G, "issecretvalue", checker)
  package.loaded["Core.Secret"] = nil
  return require("MouseOverTooltip.Core.Secret")
end

local function test_value_is_not_secret_when_api_missing()
  local Secret = load(nil)
  Assert.equal(Secret.Is("Bob"), false)
  Assert.equal(Secret.Clean("Bob"), "Bob")
end

local function test_secret_value_is_detected_and_cleaned_to_nil()
  local marker = {}
  local Secret = load(function(value)
    return value == marker
  end)
  Assert.equal(Secret.Is(marker), true)
  Assert.equal(Secret.Clean(marker), nil)
  Assert.equal(Secret.Clean(42), 42)
end

local function test_clean_passes_extra_returns_only_when_first_is_clean()
  local marker = {}
  local Secret = load(function(value)
    return value == marker
  end)
  local name, realm = Secret.Clean2("Bob", "Stormrage")
  Assert.equal(name, "Bob")
  Assert.equal(realm, "Stormrage")
  name, realm = Secret.Clean2("Bob", marker)
  Assert.equal(name, "Bob")
  Assert.equal(realm, nil)
end

return function()
  test_value_is_not_secret_when_api_missing()
  test_secret_value_is_detected_and_cleaned_to_nil()
  test_clean_passes_extra_returns_only_when_first_is_clean()
end
