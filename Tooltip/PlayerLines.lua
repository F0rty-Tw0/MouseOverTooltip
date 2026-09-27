local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Color = ns.Color or require("MouseOverTooltip.Core.Color")
local FlavorCompat = ns.FlavorCompat or require("MouseOverTooltip.Core.FlavorCompat")
local Group = ns.Group or require("MouseOverTooltip.Data.Group")
local InspectCache = ns.InspectCache or require("MouseOverTooltip.Data.InspectCache")
local Lines = ns.TooltipLines or require("MouseOverTooltip.Tooltip.Lines")
local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")
local Mount = ns.Mount or require("MouseOverTooltip.Data.Mount")
local MythicPlus = ns.MythicPlus or require("MouseOverTooltip.Data.MythicPlus")
local PlayerHeader = ns.PlayerHeader or require("MouseOverTooltip.Tooltip.PlayerHeader")
local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local concat = table.concat

local ROLE_TEXT = { TANK = "Tank", HEALER = "Healer", DAMAGER = "DPS" }
local SOURCE_R, SOURCE_G, SOURCE_B = 1, 1, 0.6

local PlayerLines = {}

local function wantsInspect(db)
  return (db.showItemLevel and FlavorCompat.hasItemLevel)
    or (db.showSpec and FlavorCompat.hasSpec)
    or (db.showPvpRating and FlavorCompat.hasPvpRating)
end

local function specInfo(entry, db)
  if not (db.showSpec and entry and entry.specID) then
    return nil, nil
  end
  local _, name, _, _, role = _G.GetSpecializationInfoByID(entry.specID)
  return name, ROLE_TEXT[role]
end

-- Lines ClearNoise blanked; new lines fill them before appending, so no
-- empty gap stays under the header.
local freed = {}
local freedCount, freedNext = 0, 1

local function emit(tooltip, text, r, g, b, wrap)
  if freedNext <= freedCount then
    local index = freed[freedNext]
    freedNext = freedNext + 1
    Lines.Set(index, text)
    Lines.left[index]:SetTextColor(r, g, b)
    return
  end
  tooltip:AddLine(text, r, g, b, wrap)
end

local function add(tooltip, text)
  if text then
    emit(tooltip, text, 1, 1, 1)
  end
end

-- Guild, realm and level text, written top-down into Blizzard's header
-- lines (2..level line); unused slots are freed for the info lines below.
local body = {}
local bodyCount = 0

local function pushBody(text)
  if text and text ~= "" then
    bodyCount = bodyCount + 1
    body[bodyCount] = text
  end
end

local function writeBody(levelIndex)
  local slots = levelIndex - 1
  for slot = 1, slots do
    local index = slot + 1
    if slot == slots and bodyCount > slots then
      Lines.Set(index, concat(body, "\n", slot, bodyCount))
    elseif slot <= bodyCount then
      Lines.Set(index, body[slot])
    else
      Lines.Set(index, nil)
      freedCount = freedCount + 1
      freed[freedCount] = index
    end
  end
end

local function wantsLevelLine(db, specName)
  return db.showLevel or db.showRace or db.showClass or db.showFaction or specName ~= nil
end

local function applyHeader(tooltip, unit, guid, db, specName)
  local className, classFile = _G.UnitClass(unit)
  className, classFile = Secret.Clean(className), Secret.Clean(classFile)
  local classCode = (db.colorName or db.showClass) and Color.Class(classFile) or nil
  local realm = PlayerHeader.Name(unit, guid, db, db.colorName and classCode or nil)
  realm = db.showRealmStatus and realm or nil
  local numLines = tooltip:NumLines()
  local levelIndex = Lines.FindLevel(numLines)
  if not levelIndex then
    if realm then
      Lines.Set(1, (Lines.Text(1) or "") .. "\n" .. realm)
    end
    return
  end
  bodyCount = 0
  pushBody(db.showGuild and PlayerHeader.Guild(unit, db))
  pushBody(realm)
  if wantsLevelLine(db, specName) then
    pushBody(PlayerHeader.Level(unit, db, classCode, className, specName) or Lines.Text(levelIndex))
  end
  writeBody(levelIndex)
  freedCount = PlayerHeader.ClearNoise(levelIndex + 1, numLines, className, freed, freedCount)
end

local function wantsHeader(db)
  return db.colorName
    or db.showGuild
    or db.showLevel
    or db.showRace
    or db.showClass
    or db.showFaction
    or db.showTitle
    or db.showRealmStatus
    or db.showRaidIcon
    or db.showDeadTag
    or db.showFriend
end

local function inspectLine(entry, db, roleText)
  local ilvl = db.showItemLevel and entry and entry.ilvl
  if not ilvl then
    return roleText and Localization.Text(roleText)
  end
  local text = Color.Label(Localization.Text("iLvl")) .. " " .. Color.Wrap(Color.EPIC, ilvl)
  return roleText and (text .. " • " .. Localization.Text(roleText)) or text
end

local function pvpLine(entry, db)
  if not (db.showPvpRating and entry and entry.pvpRating) then
    return nil
  end
  local text = Color.Label(Localization.Text("PvP")) .. " " .. entry.pvpRating
  return entry.pvpBracket and (text .. " (" .. entry.pvpBracket .. ")") or text
end

local function addMount(tooltip, unit, db)
  local line, source = Mount.Line(unit, db)
  add(tooltip, line)
  if source then
    emit(tooltip, source, SOURCE_R, SOURCE_G, SOURCE_B, true)
  end
end

local function addLabeled(tooltip, label, text)
  if text then
    add(tooltip, Color.Label(Localization.Text(label)) .. " " .. text)
  end
end

function PlayerLines.Apply(tooltip, unit, guid, db)
  freedCount, freedNext = 0, 1
  local entry
  if guid and wantsInspect(db) then
    entry = InspectCache.Get(guid)
    if not entry then
      InspectCache.Request(unit, guid)
    end
  end
  local specName, roleText = specInfo(entry, db)
  if wantsHeader(db) then
    applyHeader(tooltip, unit, guid, db, specName)
  end
  add(tooltip, inspectLine(entry, db, roleText))
  if db.showMythicPlus and FlavorCompat.hasMythicPlus then
    add(tooltip, MythicPlus.Line(unit))
  end
  add(tooltip, pvpLine(entry, db))
  if db.showMount and FlavorCompat.hasMountJournal then
    addMount(tooltip, unit, db)
  end
  if db.showTarget then
    addLabeled(tooltip, "Target:", Group.Target(unit))
  end
  if db.showTargetedBy then
    addLabeled(tooltip, "Targeted by:", Group.TargetedBy(unit))
  end
end

ns.PlayerLines = PlayerLines
return PlayerLines
