local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local CombatHide = {}

-- World units are default-anchored to UIParent; anything else is a frame.
function CombatHide.ShouldHide(tooltip, db)
  if not (db.hideWorldInCombat or db.hideFramesInCombat) or not _G.InCombatLockdown() then
    return false
  end
  if db.shiftShowsHidden and _G.IsShiftKeyDown() then
    return false
  end
  if tooltip:GetOwner() == _G.UIParent then
    return db.hideWorldInCombat == true
  end
  return db.hideFramesInCombat == true
end

-- True when this tooltip should stay the stock Blizzard one. The anchor passes
-- `owner` because the tooltip has no owner yet when its default anchor is set.
function CombatHide.ShowsBlizzard(tooltip, db, owner)
  if not (db.blizzardWorldInCombat or db.blizzardFramesInCombat) or not _G.InCombatLockdown() then
    return false
  end
  if (owner or tooltip:GetOwner()) == _G.UIParent then
    return db.blizzardWorldInCombat == true
  end
  return db.blizzardFramesInCombat == true
end

ns.CombatHide = CombatHide
return CombatHide
