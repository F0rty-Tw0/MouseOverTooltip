local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

-- Native cursor anchoring: the client moves the tooltip, no OnUpdate needed.
local Anchor = {}

local OFFSET_ANCHOR = "ANCHOR_CURSOR_RIGHT"

local settings
local hooked = false
local offsetHooked = false
-- True only while the tooltip holds our own offset anchor, so anchors set by
-- Blizzard or other addons are never touched. Any SetOwner on a shown tooltip
-- hides it first, so OnHide clears this; a different owner is ignored too.
-- Blizzard anchors, resizes and shows in one frame, so a resize or show in a
-- later frame before our show belongs to someone who re-anchored the
-- still-hidden tooltip (GetTime is per frame).
-- No SetOwner hook: an instance hook breaks Blizzard's GameTooltip:SetOwner on 12.0.
local offsetActive = false
local offsetShown = false
local offsetOwner
local offsetTime

local function dropIfStale()
  if not offsetShown and _G.GetTime() ~= offsetTime then
    offsetActive = false
  end
end

-- ANCHOR_CURSOR (bottom-center on the cursor) ignores offsets. ANCHOR_CURSOR_RIGHT
-- puts the bottom-left there, so shifting x by half the width keeps 0 = centered.
-- nil when the width is a secret value.
local function centeredOffsetX(tooltip)
  local width = tooltip:GetWidth()
  if Secret.Is(width) then
    return nil
  end
  return settings.cursorOffsetX - width / 2
end

-- Width changes as lines are added; fires on resize only, not per frame.
local function onSizeChanged(tooltip)
  if offsetActive then
    dropIfStale()
  end
  if not offsetActive or tooltip:GetOwner() ~= offsetOwner or tooltip:GetAnchorType() ~= OFFSET_ANCHOR then
    return
  end
  local x = centeredOffsetX(tooltip)
  if x then
    tooltip:SetAnchorType(OFFSET_ANCHOR, x, settings.cursorOffsetY)
  end
end

local function onShow()
  if offsetActive then
    dropIfStale()
    offsetShown = offsetActive
  end
end

local function onHide()
  offsetActive = false
end

-- Installed on first offset use, so players at 0/0 never pay for them.
local function installOffsetHooks(tooltip)
  if offsetHooked then
    return
  end
  offsetHooked = true
  tooltip:HookScript("OnSizeChanged", onSizeChanged)
  tooltip:HookScript("OnShow", onShow)
  tooltip:HookScript("OnHide", onHide)
end

local function onDefaultAnchor(tooltip, parent)
  if not (settings.followCursor and tooltip == _G.GameTooltip) then
    return
  end
  -- Nameplates are forbidden in instances; SetOwner on one throws from addon code.
  if parent and parent.IsForbidden and parent:IsForbidden() then
    return
  end
  local x = (settings.cursorOffsetX ~= 0 or settings.cursorOffsetY ~= 0) and centeredOffsetX(tooltip)
  if not x then
    tooltip:SetOwner(parent, "ANCHOR_CURSOR")
    return
  end
  tooltip:SetOwner(parent, OFFSET_ANCHOR, x, settings.cursorOffsetY)
  installOffsetHooks(tooltip)
  offsetOwner = parent
  offsetTime = _G.GetTime()
  offsetShown = false
  offsetActive = true
end

function Anchor.Install(db)
  settings = db
  if hooked or type(_G.GameTooltip_SetDefaultAnchor) ~= "function" then
    return
  end
  hooked = true
  _G.hooksecurefunc("GameTooltip_SetDefaultAnchor", onDefaultAnchor)
end

ns.Anchor = Anchor
return Anchor
