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
-- True only while the tooltip holds our own offset anchor; any other SetOwner
-- (Blizzard, other addons) clears it, so their anchors are never touched.
local offsetActive = false

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
  if not offsetActive or tooltip:GetAnchorType() ~= OFFSET_ANCHOR then
    return
  end
  local x = centeredOffsetX(tooltip)
  if x then
    tooltip:SetAnchorType(OFFSET_ANCHOR, x, settings.cursorOffsetY)
  end
end

local function onSetOwner()
  offsetActive = false
end

-- Installed on first offset use, so players at 0/0 never pay for them.
local function installOffsetHooks(tooltip)
  if offsetHooked then
    return
  end
  offsetHooked = true
  _G.hooksecurefunc(tooltip, "SetOwner", onSetOwner)
  tooltip:HookScript("OnSizeChanged", onSizeChanged)
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
