local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

-- Tooltip size. Set on load and on slider change only, never per hover, so
-- addons that set the scale themselves win.
local Scale = {}

local NORMAL_PERCENT = 100
-- Comparison tooltips scale with GameTooltip so side-by-side tooltips match.
local FRAME_NAMES = { "GameTooltip", "ShoppingTooltip1", "ShoppingTooltip2" }

function Scale.Apply(percent)
  local scale = percent / NORMAL_PERCENT
  for _, name in ipairs(FRAME_NAMES) do
    local frame = _G[name]
    if frame and frame.SetScale then
      frame:SetScale(scale)
    end
  end
end

-- At normal size the frames are left alone: no API calls.
function Scale.Install(db)
  if db.tooltipScale ~= NORMAL_PERCENT then
    Scale.Apply(db.tooltipScale)
  end
end

ns.Scale = Scale
return Scale
