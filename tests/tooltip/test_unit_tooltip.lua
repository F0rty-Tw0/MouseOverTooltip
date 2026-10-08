local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

local postCalls = {}
_G.Enum = { TooltipDataType = { Item = 0, Unit = 2 } }
_G.TooltipDataProcessor = {
  AddTooltipPostCall = function(dataType, fn)
    postCalls[dataType] = fn
  end,
}
_G.C_PaperDollInfo = {
  GetInspectItemLevel = function()
    return 639
  end,
}

local SavedState = require("MouseOverTooltip.Settings.SavedState")
local InspectCache = require("MouseOverTooltip.Data.InspectCache")
local UnitTooltip = require("MouseOverTooltip.Tooltip.UnitTooltip")

local db = SavedState.Initialize(nil)
InspectCache.Configure({ onReady = UnitTooltip.Refresh })
UnitTooltip.Install(db)

local function hoverBob()
  W.units = {
    player = { name = "Me", guid = "Player-me", isPlayer = true },
    mouseover = { name = "Bob", guid = "Player-1", isPlayer = true, className = "Mage", classFile = "MAGE", race = "Human", level = 80 },
  }
  W.SetTooltipLines("mouseover", { "Bob", "Level 80 Human Mage (Player)" })
  postCalls[2](W.tooltip)
end

local function test_retail_uses_tooltip_data_post_calls()
  Assert.equal(type(postCalls[2]), "function")
  Assert.equal(type(postCalls[0]), "function")
end

local function test_unit_post_call_styles_player()
  hoverBob()
  Assert.equal(W.LineText(1), "|cff40c7ebBob|r")
end

local function test_other_tooltips_are_ignored()
  W.units = { mouseover = { name = "Bob", guid = "Player-1", isPlayer = true } }
  W.SetTooltipLines("mouseover", { "Bob" })
  postCalls[2]({})
  Assert.equal(W.LineText(1), "Bob")
end

local function test_refresh_after_mouse_left_does_not_cancel_fade()
  hoverBob()
  local shows = 0
  local show = W.tooltip.Show
  W.tooltip.Show = function(self)
    shows = shows + 1
    return show(self)
  end
  W.units.mouseover = nil
  postCalls[2](W.tooltip)
  W.tooltip.Show = show
  Assert.equal(shows, 0, "Show() would cancel Blizzard's fade-out")
end

local function test_inspect_result_refreshes_shown_tooltip()
  hoverBob()
  W.RunTimers()
  W.calls.RefreshData = nil
  for _, frame in ipairs(W.frames) do
    frame:FireEvent("INSPECT_READY", "Player-1")
  end
  Assert.equal(W.calls.RefreshData, 1)
end

local function test_refresh_skipped_when_another_unit_is_shown()
  W.calls.RefreshData = nil
  W.units.mouseover = { name = "Amy", guid = "Player-2", isPlayer = true }
  UnitTooltip.Refresh("Player-1")
  Assert.equal(W.calls.RefreshData, nil)
end

local function test_combat_hide_hides_before_any_styling()
  db.hideWorldInCombat = true
  W.inCombat = true
  W.tooltip:SetOwner(_G.UIParent, "ANCHOR_NONE")
  hoverBob()
  Assert.equal(W.tooltip.shown, false)
  Assert.equal(W.LineText(1), "Bob")
  db.hideWorldInCombat = false
  W.inCombat = false
end

-- Mythic+ hands out the shown unit token as a secret; hiding the bar needs no unit.
local function test_secret_unit_still_hides_health_bar()
  local marker = {}
  rawset(_G, "issecretvalue", function(v)
    return v == marker
  end)
  package.loaded["Core.Secret"] = nil
  for key in pairs(package.loaded) do
    if string.find(key, "^Tooltip%.") then
      package.loaded[key] = nil
    end
  end
  local secretDb = SavedState.Initialize(nil)
  secretDb.hideHealthBar = true
  require("MouseOverTooltip.Tooltip.UnitTooltip").Install(secretDb)
  local getUnit = W.tooltip.GetUnit
  W.tooltip.GetUnit = function()
    return nil, marker
  end
  _G.GameTooltipStatusBar:Show()
  postCalls[2](W.tooltip)
  W.tooltip.GetUnit = getUnit
  rawset(_G, "issecretvalue", nil)
  package.loaded["Core.Secret"] = nil
  Assert.equal(_G.GameTooltipStatusBar.shown, false)
end

local function test_classic_hooks_tooltip_scripts()
  W = Wow.Install()
  W.scriptSupport.OnTooltipSetUnit = true
  W.scriptSupport.OnTooltipSetItem = true
  for key in pairs(package.loaded) do
    if string.find(key, "^Tooltip%.") then
      package.loaded[key] = nil
    end
  end
  local ClassicUnitTooltip = require("MouseOverTooltip.Tooltip.UnitTooltip")
  ClassicUnitTooltip.Install(SavedState.Initialize(nil))
  Assert.equal(#W.tooltip.hooks.OnTooltipSetUnit, 1)
  Assert.equal(#W.tooltip.hooks.OnTooltipSetItem, 1)
end

return function()
  test_retail_uses_tooltip_data_post_calls()
  test_unit_post_call_styles_player()
  test_other_tooltips_are_ignored()
  test_refresh_after_mouse_left_does_not_cancel_fade()
  test_inspect_result_refreshes_shown_tooltip()
  test_refresh_skipped_when_another_unit_is_shown()
  test_combat_hide_hides_before_any_styling()
  test_secret_unit_still_hides_health_bar()
  test_classic_hooks_tooltip_scripts()
end
