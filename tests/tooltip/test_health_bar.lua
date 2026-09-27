local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

-- Blizzard feeds the tooltip bar a 0-1 fraction, never hit points.
local bar = _G.GameTooltipStatusBar
bar.value = 0.25
function bar:GetValue()
  return self.value
end
local created = {}
function bar:CreateFontString()
  local fs = { shown = true }
  function fs:SetPoint() end
  function fs:SetText(t)
    self.text = t
  end
  function fs:Show()
    self.shown = true
  end
  function fs:Hide()
    self.shown = false
  end
  table.insert(created, fs)
  return fs
end
local secret = {}
_G.AbbreviateNumbers = function(v)
  if v == secret then
    return "S"
  end
  return math.floor(v / 1000) .. "K"
end
W.units.mouseover = { name = "Bob", health = 50000, healthMax = 200000 }
_G.UnitHealth = function(unit)
  return W.units[unit].health
end
_G.UnitHealthMax = function(unit)
  return W.units[unit].healthMax
end
local HealthBar = require("MouseOverTooltip.Tooltip.HealthBar")

local function test_everything_off_creates_nothing()
  HealthBar.Apply({ healthText = false, hideHealthBar = false }, "mouseover")
  Assert.equal(#created, 0)
  Assert.equal(bar.hooks.OnValueChanged, nil)
end

local function test_health_text_shows_unit_health_not_bar_fraction()
  HealthBar.Apply({ healthText = true, hideHealthBar = false }, "mouseover")
  Assert.equal(created[1].text, "50K / 200K")
  W.units.mouseover.health = 25000
  bar:Fire("OnValueChanged", 0.125)
  Assert.equal(created[1].text, "25K / 200K")
end

local function test_secret_health_is_abbreviated_without_comparing()
  local marker = secret
  rawset(_G, "issecretvalue", function(v)
    return v == marker
  end)
  package.loaded["Core.Secret"] = nil
  package.loaded["Tooltip.HealthBar"] = nil
  local SecretHealthBar = require("MouseOverTooltip.Tooltip.HealthBar")
  W.units.mouseover = { name = "Boss", health = secret, healthMax = secret }
  SecretHealthBar.Apply({ healthText = true, hideHealthBar = false }, "mouseover")
  Assert.equal(created[#created].text, "S / S")
  rawset(_G, "issecretvalue", nil)
  W.units.mouseover = { name = "Bob", health = 50000, healthMax = 200000 }
end

local function test_disabling_health_text_hides_it()
  HealthBar.Apply({ healthText = false, hideHealthBar = false }, "mouseover")
  bar:Fire("OnValueChanged", 0.5)
  Assert.equal(created[1].shown, false)
end

local function test_hide_health_bar()
  bar.shown = true
  HealthBar.Apply({ healthText = false, hideHealthBar = true }, "mouseover")
  Assert.equal(bar.shown, false)
end

return function()
  test_everything_off_creates_nothing()
  test_health_text_shows_unit_health_not_bar_fraction()
  test_secret_health_is_abbreviated_without_comparing()
  test_disabling_health_text_hides_it()
  test_hide_health_bar()
end
