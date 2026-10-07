local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Constants = ns.Constants or require("MouseOverTooltip.Core.Constants")
local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")

local cos, sin, rad, deg = math.cos, math.sin, math.rad, math.deg
-- WoW runs Lua 5.1 (atan2); the test harness may run 5.3+ (two-arg atan).
local atan2 = math.atan2 or math.atan

local SIZE = 31
local RING_OFFSET = 5
local ICON = "Interface\\AddOns\\MouseOverTooltip\\Media\\Icon"
local BORDER = "Interface\\Minimap\\MiniMap-TrackingBorder"
local BACKGROUND = "Interface\\Minimap\\UI-Minimap-Background"
local HIGHLIGHT = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"

-- While dragged, an OnUpdate keeps the button on the ring at the cursor's
-- angle; it is removed on drop, so an idle button runs nothing per frame.
-- ponytail: round ring only; square minimap addons get a circle too.
local MinimapButton = {}

local button
local settings

local function place(frame, angle)
  local minimap = _G.Minimap
  local radius = (minimap:GetWidth() or 140) / 2 + RING_OFFSET
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", minimap, "CENTER", cos(rad(angle)) * radius, sin(rad(angle)) * radius)
end

local function followCursor(frame)
  local minimap = _G.Minimap
  local mx, my = minimap:GetCenter()
  local cx, cy = _G.GetCursorPosition()
  local scale = minimap:GetEffectiveScale()
  settings.minimapAngle = deg(atan2(cy / scale - my, cx / scale - mx)) % 360
  place(frame, settings.minimapAngle)
end

local function onDragStart(frame)
  frame:SetScript("OnUpdate", followCursor)
end

local function onDragStop(frame)
  frame:SetScript("OnUpdate", nil)
end

local function addTexture(frame, layer, path, size, point)
  local texture = frame:CreateTexture(nil, layer)
  texture:SetTexture(path)
  texture:SetSize(size, size)
  texture:SetPoint(point or "CENTER", frame, point or "CENTER")
  return texture
end

local function create(onClick)
  local frame = _G.CreateFrame("Button", "MouseOverTooltipMinimapButton", _G.Minimap)
  frame:SetSize(SIZE, SIZE)
  frame:SetFrameStrata("MEDIUM")
  frame:SetFrameLevel(8)
  frame:RegisterForClicks("AnyUp")
  frame:RegisterForDrag("LeftButton")
  frame:SetHighlightTexture(HIGHLIGHT)
  addTexture(frame, "BACKGROUND", BACKGROUND, 20)
  addTexture(frame, "ARTWORK", ICON, 18)
  addTexture(frame, "OVERLAY", BORDER, 53, "TOPLEFT")
  frame:SetScript("OnClick", onClick)
  frame:SetScript("OnDragStart", onDragStart)
  frame:SetScript("OnDragStop", onDragStop)
  frame:SetScript("OnEnter", function(self)
    local tooltip = _G.GameTooltip
    tooltip:SetOwner(self, "ANCHOR_LEFT")
    tooltip:SetText(Constants.TITLE)
    tooltip:AddLine(Localization.Text("Click to open settings. Drag to move."), 1, 1, 1)
    tooltip:Show()
  end)
  frame:SetScript("OnLeave", function()
    _G.GameTooltip:Hide()
  end)
  place(frame, settings.minimapAngle)
  return frame
end

-- Created on first show only; a hidden button costs nothing.
function MinimapButton.SetShown(db, shown, onClick)
  settings = db
  if shown and not button then
    button = create(onClick)
  end
  if button then
    button:SetShown(shown)
  end
end

ns.MinimapButton = MinimapButton
return MinimapButton
