local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
Wow.Install()

local auras
local collected = true
_G.C_UnitAuras = {
  GetAuraDataByIndex = function(_unit, index)
    return auras[index]
  end,
}
_G.C_MountJournal = {
  GetMountFromSpell = function(spellId)
    return spellId == 42777 and 7 or nil
  end,
  GetMountInfoByID = function()
    return "Swift Spectral Tiger", 42777, 132242, false, true, 0, false, false, nil, false, collected
  end,
  GetMountInfoExtraByID = function()
    return 1, "desc", "|cFFFFD200Drop:|r Trading Card|nRare"
  end,
}
local Mount = require("MouseOverTooltip.Data.Mount")

local function db(overrides)
  local d = { showMountIcon = false, showMountSource = false, mountOnlyUncollected = false }
  for k, v in pairs(overrides or {}) do
    d[k] = v
  end
  return d
end

local function test_mount_line_names_active_mount_with_collected_state()
  auras = { { spellId = 1 }, { spellId = 42777 } }
  collected = true
  local line = Mount.Line("mouseover", db())
  Assert.contains(line, "|cffffd100Mount:|r Swift Spectral Tiger")
  Assert.contains(line, "ReadyCheck-Ready")
end

local function test_no_line_when_not_mounted()
  auras = { { spellId = 1 } }
  Assert.equal(Mount.Line("mouseover", db()), nil)
end

local function test_icon_only_when_enabled()
  auras = { { spellId = 42777 } }
  Assert.notContains(Mount.Line("mouseover", db()), "132242")
  Assert.contains(Mount.Line("mouseover", db({ showMountIcon = true })), "|T132242:0|t")
end

local function test_source_shown_only_when_not_collected_and_enabled()
  auras = { { spellId = 42777 } }
  collected = false
  local line, source = Mount.Line("mouseover", db({ showMountSource = true }))
  Assert.contains(line, "ReadyCheck-NotReady")
  Assert.equal(source, "Drop: Trading Card Rare")
  collected = true
  local _, collectedSource = Mount.Line("mouseover", db({ showMountSource = true }))
  Assert.equal(collectedSource, nil)
end

local function test_only_uncollected_hides_collected_mounts()
  auras = { { spellId = 42777 } }
  collected = true
  Assert.equal(Mount.Line("mouseover", db({ mountOnlyUncollected = true })), nil)
  collected = false
  Assert.contains(Mount.Line("mouseover", db({ mountOnlyUncollected = true })), "Swift Spectral Tiger")
end

local function test_secret_spell_id_is_skipped()
  local marker = {}
  rawset(_G, "issecretvalue", function(v)
    return v == marker
  end)
  package.loaded["Core.Secret"] = nil
  package.loaded["Data.Mount"] = nil
  local SecretMount = require("MouseOverTooltip.Data.Mount")
  auras = { { spellId = marker } }
  Assert.equal(SecretMount.Line("mouseover", db()), nil)
  rawset(_G, "issecretvalue", nil)
end

return function()
  test_mount_line_names_active_mount_with_collected_state()
  test_no_line_when_not_mounted()
  test_icon_only_when_enabled()
  test_source_shown_only_when_not_collected_and_enabled()
  test_only_uncollected_hides_collected_mounts()
  test_secret_spell_id_is_skipped()
end
