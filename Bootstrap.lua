local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Anchor = ns.Anchor or require("MouseOverTooltip.Tooltip.Anchor")
local Constants = ns.Constants or require("MouseOverTooltip.Core.Constants")
local FlavorCompat = ns.FlavorCompat or require("MouseOverTooltip.Core.FlavorCompat")
local InspectCache = ns.InspectCache or require("MouseOverTooltip.Data.InspectCache")
local MinimapButton = ns.MinimapButton or require("MouseOverTooltip.UI.MinimapButton")
local Panel = ns.SettingsPanel or require("MouseOverTooltip.Settings.Panel")
local PvP = ns.PvP or require("MouseOverTooltip.Data.PvP")
local SavedState = ns.SavedState or require("MouseOverTooltip.Settings.SavedState")
local SlashCommand = ns.SlashCommand or require("MouseOverTooltip.Core.SlashCommand")
local UnitTooltip = ns.UnitTooltip or require("MouseOverTooltip.Tooltip.UnitTooltip")

local ADDON_NAME = "MouseOverTooltip"

local Bootstrap = {}

local function openSettings()
  Panel.Open()
end

function Bootstrap.Initialize(saved)
  local db = SavedState.Initialize(saved)
  InspectCache.Configure({
    skipInCombat = function()
      return db.skipInspectInCombat
    end,
    onReady = UnitTooltip.Refresh,
    wantsPvp = function()
      return db.showPvpRating and FlavorCompat.hasPvpRating
    end,
    readPvp = PvP.Read,
  })
  UnitTooltip.Install(db)
  -- Retail-only file: absent on Classic, so no require fallback here.
  if ns.LineFilter then
    ns.LineFilter.Install(db)
  end
  Anchor.Install(db)
  Panel.Register(db, function(key, value)
    if key == "minimapButton" then
      MinimapButton.SetShown(db, value, openSettings)
    end
  end)
  MinimapButton.SetShown(db, db.minimapButton, openSettings)
  SlashCommand.Register(openSettings)
  return db
end

-- AddOn Compartment (Retail): names declared in the TOC.
_G.MouseOverTooltip_OnAddonCompartmentClick = openSettings

function _G.MouseOverTooltip_OnAddonCompartmentEnter(_, button)
  local tooltip = _G.GameTooltip
  tooltip:SetOwner(button, "ANCHOR_LEFT")
  tooltip:SetText(Constants.TITLE)
  tooltip:Show()
end

function _G.MouseOverTooltip_OnAddonCompartmentLeave()
  _G.GameTooltip:Hide()
end

if type(_G.CreateFrame) == "function" then
  local loader = _G.CreateFrame("Frame")
  loader:RegisterEvent("ADDON_LOADED")
  loader:SetScript("OnEvent", function(self, _event, loadedName)
    if loadedName ~= ADDON_NAME then
      return
    end
    self:UnregisterEvent("ADDON_LOADED")
    _G.MouseOverTooltipDB = Bootstrap.Initialize(_G.MouseOverTooltipDB)
  end)
end

ns.Bootstrap = Bootstrap
return Bootstrap
