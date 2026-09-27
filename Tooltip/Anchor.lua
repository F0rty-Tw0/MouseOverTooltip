local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

-- Native cursor anchoring: the client moves the tooltip, no OnUpdate needed.
local Anchor = {}

local settings
local hooked = false

local function onDefaultAnchor(tooltip, parent)
  if settings.followCursor and tooltip == _G.GameTooltip then
    tooltip:SetOwner(parent, "ANCHOR_CURSOR")
  end
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
