local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

local FlavorCompat = require("MouseOverTooltip.Core.FlavorCompat")
local PlayerHeader = require("MouseOverTooltip.Tooltip.PlayerHeader")

-- WoW: Forever's UnitName returns (name, surname); the stub's `realm` is that second value.
local function foreverName(separator, unitOverrides, db)
  _G.Constants = separator and { CharacterNameSeparatorConsts = { CHARACTERNAME_SURNAME_SEPARATOR = separator } }
  W.units = { mouseover = { name = "Bob", realm = "Smith", isPlayer = true } }
  for k, v in pairs(unitOverrides or {}) do
    W.units.mouseover[k] = v
  end
  W.SetTooltipLines("mouseover", { "Bob" })
  FlavorCompat.isForever = true
  local realm = PlayerHeader.Name("mouseover", nil, db or {}, nil)
  FlavorCompat.isForever = false
  _G.Constants = nil
  return W.LineText(1), realm
end

local function test_forever_joins_surname_with_blizzard_separator()
  local line, realm = foreverName("_")
  Assert.equal(line, "Bob_Smith")
  Assert.equal(realm, nil, "surname is never returned as a realm")
end

local function test_forever_without_separator_constant_uses_space()
  Assert.equal((foreverName(nil)), "Bob Smith")
end

local function test_forever_empty_surname_adds_no_separator()
  Assert.equal((foreverName(" ", { realm = "" })), "Bob")
end

local function test_forever_title_from_pvp_name_with_surname()
  Assert.equal((foreverName(" ", { pvpName = "Private Bob Smith" }, { showTitle = true })), "Bob Smith - Private")
end

local function test_forever_title_from_pvp_name_with_first_name_only()
  Assert.equal((foreverName(" ", { pvpName = "Private Bob" }, { showTitle = true })), "Bob Smith - Private")
end

return function()
  test_forever_joins_surname_with_blizzard_separator()
  test_forever_without_separator_constant_uses_space()
  test_forever_empty_surname_adds_no_separator()
  test_forever_title_from_pvp_name_with_surname()
  test_forever_title_from_pvp_name_with_first_name_only()
end
