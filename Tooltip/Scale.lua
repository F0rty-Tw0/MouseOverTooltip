local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

-- Tooltip size. Set on load and on slider change only, never per hover, so
-- addons that set the scale later or on each show win. Exception: a stock
-- Blizzard unit tooltip in combat shows at normal size (UseNormal) and the user
-- scale returns on the next tooltip clear, overriding such addons then.
local Scale = {}

local NORMAL_PERCENT = 100
-- Comparison tooltips scale with GameTooltip so side-by-side tooltips match.
local FRAME_NAMES = { "GameTooltip", "ShoppingTooltip1", "ShoppingTooltip2" }

local settings
local switched = false
local clearHooked = false

function Scale.Apply(percent)
  local scale = percent / NORMAL_PERCENT
  for _, name in ipairs(FRAME_NAMES) do
    local frame = _G[name]
    if frame and frame.SetScale then
      frame:SetScale(scale)
    end
  end
end

-- Reads the scale at clear time, so a slider move meanwhile wins.
local function restore()
  if switched then
    switched = false
    Scale.Apply(settings.tooltipScale)
  end
end

-- At normal size, or already switched since the last clear (unit frames
-- refresh often): no API calls. The clear hook installs on first use only.
function Scale.UseNormal(tooltip, db)
  settings = db
  if switched or db.tooltipScale == NORMAL_PERCENT then
    return
  end
  switched = true
  tooltip:SetScale(1)
  if not clearHooked then
    clearHooked = true
    tooltip:HookScript("OnTooltipCleared", restore)
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
