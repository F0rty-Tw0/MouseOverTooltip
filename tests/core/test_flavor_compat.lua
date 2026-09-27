local Assert = require("tests.helpers.assert")

local API_GLOBALS = {
  "WOW_PROJECT_ID",
  "WOW_PROJECT_MAINLINE",
  "GetBuildInfo",
  "C_PlayerInfo",
  "C_PaperDollInfo",
  "GetInspectSpecialization",
  "GetSpecializationInfoByID",
  "GetInspectArenaData",
  "C_MountJournal",
  "WOW_PROJECT_MISTS_CLASSIC",
  "WOW_PROJECT_CATACLYSM_CLASSIC",
  "C_SpecializationInfo",
}

local function load(globals)
  for _, name in ipairs(API_GLOBALS) do
    rawset(_G, name, globals[name])
  end
  package.loaded["Core.FlavorCompat"] = nil
  return require("MouseOverTooltip.Core.FlavorCompat")
end

local function buildInfo(toc)
  local function test_spec_hidden_on_flavors_without_specs()
    local apis = {
      WOW_PROJECT_ID = 2,
      WOW_PROJECT_MAINLINE = 1,
      GetBuildInfo = buildInfo(11509),
      GetInspectSpecialization = function() end,
      GetSpecializationInfoByID = function() end,
    }
    Assert.equal(load(apis).hasSpec, false, "Classic Era")
    Assert.equal(load(retailApis(16001)).hasSpec, false, "Forever")
  end

  local function test_spec_available_on_mists()
    local apis = {
      WOW_PROJECT_ID = 19,
      WOW_PROJECT_MAINLINE = 1,
      WOW_PROJECT_MISTS_CLASSIC = 19,
      GetBuildInfo = buildInfo(50504),
      GetInspectSpecialization = function() end,
      GetSpecializationInfoByID = function() end,
    }
    Assert.equal(load(apis).hasSpec, true)
  end

  return function()
    return "x", "1", "d", toc
  end
end

local function retailApis(toc)
  return {
    WOW_PROJECT_ID = 1,
    WOW_PROJECT_MAINLINE = 1,
    GetBuildInfo = buildInfo(toc),
    C_PlayerInfo = { GetPlayerMythicPlusRatingSummary = function() end },
    C_PaperDollInfo = { GetInspectItemLevel = function() end },
    GetInspectSpecialization = function() end,
    GetSpecializationInfoByID = function() end,
    GetInspectArenaData = function() end,
    C_MountJournal = { GetMountFromSpell = function() end },
  }
end

local function test_retail_enables_every_feature()
  local Flavor = load(retailApis(120100))
  Assert.equal(Flavor.isRetail, true)
  Assert.equal(Flavor.hasMythicPlus, true)
  Assert.equal(Flavor.hasItemLevel, true)
  Assert.equal(Flavor.hasSpec, true)
  Assert.equal(Flavor.hasPvpRating, true)
  Assert.equal(Flavor.hasMountJournal, true)
end

local function test_forever_has_no_mythic_plus_or_pvp_rating()
  local Flavor = load(retailApis(16001))
  Assert.equal(Flavor.hasMythicPlus, false)
  Assert.equal(Flavor.hasPvpRating, false)
end

local function test_vanilla_hides_features_whose_api_is_missing()
  local Flavor = load({ WOW_PROJECT_ID = 2, WOW_PROJECT_MAINLINE = 1, GetBuildInfo = buildInfo(11509) })
  Assert.equal(Flavor.isRetail, false)
  Assert.equal(Flavor.hasMythicPlus, false)
  Assert.equal(Flavor.hasItemLevel, false)
  Assert.equal(Flavor.hasSpec, false)
  Assert.equal(Flavor.hasPvpRating, false)
  Assert.equal(Flavor.hasMountJournal, false)
end

local function test_spec_hidden_on_flavors_without_specs()
  local apis = {
    WOW_PROJECT_ID = 2,
    WOW_PROJECT_MAINLINE = 1,
    GetBuildInfo = buildInfo(11509),
    GetInspectSpecialization = function() end,
    GetSpecializationInfoByID = function() end,
  }
  Assert.equal(load(apis).hasSpec, false, "Classic Era")
  Assert.equal(load(retailApis(16001)).hasSpec, false, "Forever")
end

local function test_spec_available_on_mists()
  local apis = {
    WOW_PROJECT_ID = 19,
    WOW_PROJECT_MAINLINE = 1,
    WOW_PROJECT_MISTS_CLASSIC = 19,
    GetBuildInfo = buildInfo(50504),
    GetInspectSpecialization = function() end,
    GetSpecializationInfoByID = function() end,
  }
  Assert.equal(load(apis).hasSpec, true)
end

return function()
  test_retail_enables_every_feature()
  test_forever_has_no_mythic_plus_or_pvp_rating()
  test_vanilla_hides_features_whose_api_is_missing()
  test_spec_hidden_on_flavors_without_specs()
  test_spec_available_on_mists()
end
