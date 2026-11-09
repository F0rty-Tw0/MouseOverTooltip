local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local CombatHide = ns.CombatHide or require("MouseOverTooltip.Tooltip.CombatHide")
local Lines = ns.TooltipLines or require("MouseOverTooltip.Tooltip.Lines")

-- Blizzard's unit frames (player, party, raid) append a blank line and
-- "<Right click for Frame Settings>" after SetUnit, outside tooltip data, so
-- a post-hook blanks both. Runs only while a unit frame is hovered.
local UnitFrameHint = {}

local BLANK = " "

local settings

local function clear(index)
  Lines.Set(index, nil)
  local line = Lines.left[index]
  if line then
    line:Hide()
  end
end

local function stripHint()
  local tooltip = _G.GameTooltip
  -- The Show() below must not undo a combat hide from the SetUnit hook.
  if not tooltip:IsShown() or CombatHide.ShouldHide(tooltip, settings) then
    return
  end
  if CombatHide.ShowsBlizzard(tooltip, settings) then
    return
  end
  local last = tooltip:NumLines()
  if last < 1 or Lines.Text(last) ~= _G.UNIT_POPUP_RIGHT_CLICK then
    return
  end
  clear(last)
  if last > 1 and Lines.Text(last - 1) == BLANK then
    clear(last - 1)
  end
  tooltip:Show()
end

function UnitFrameHint.Install(db)
  settings = db
  if _G.UNIT_POPUP_RIGHT_CLICK and _G.UnitFrame_UpdateTooltip then
    _G.hooksecurefunc("UnitFrame_UpdateTooltip", stripHint)
  end
end

ns.UnitFrameHint = UnitFrameHint
return UnitFrameHint
