local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Color = ns.Color or require("MouseOverTooltip.Core.Color")
local EnemyForces = ns.EnemyForces or require("MouseOverTooltip.Data.EnemyForces")
local FlavorCompat = ns.FlavorCompat or require("MouseOverTooltip.Core.FlavorCompat")
local Lines = ns.TooltipLines or require("MouseOverTooltip.Tooltip.Lines")
local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")
local Quest = ns.Quest or require("MouseOverTooltip.Data.Quest")
local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")
local UnitTags = ns.UnitTags or require("MouseOverTooltip.Tooltip.UnitTags")

local concat = table.concat
local gsub = string.gsub
local match = string.match
local tostring = tostring

local OWNER_LINES_MAX = 3
local TAPPED_GRAY = 0.5
local DONE_R, DONE_G, DONE_B = 0.2, 1, 0.2
local CLASSIFICATION = {
  worldboss = { "Boss", "|cffff2020" },
  rareelite = { "Rare Elite", "|cffc8c8ff" },
  elite = { "Elite", "|cffffd100" },
  rare = { "Rare", "|cffc0c0c0" },
}
local OWNER_FORMATS = {
  "UNITNAME_TITLE_PET",
  "UNITNAME_TITLE_MINION",
  "UNITNAME_TITLE_GUARDIAN",
  "UNITNAME_TITLE_COMPANION",
  "UNITNAME_TITLE_CHARM",
  "UNITNAME_TITLE_CREATION",
}

local NpcLines = {}

local parts = {}
local count = 0
local function push(text)
  if text then
    count = count + 1
    parts[count] = text
  end
end

local function classifiedLevel(unit)
  local level = _G.UnitLevel(unit)
  if Secret.Is(level) or type(level) ~= "number" then
    return nil
  end
  count = 0
  push(Color.Wrap(Color.Difficulty(unit, level), level > 0 and tostring(level) or "??"))
  local class = CLASSIFICATION[Secret.Clean(_G.UnitClassification(unit))]
  if class then
    push(Color.Wrap(class[2], Localization.Text(class[1])))
  end
  push(Secret.Clean(_G.UnitCreatureType(unit)))
  return concat(parts, " ", 1, count)
end

local function reactionText(unit)
  local reaction = Secret.Clean(_G.UnitReaction(unit, "player"))
  local label = reaction and _G["FACTION_STANDING_LABEL" .. reaction]
  local code = Color.Reaction(reaction)
  return label and code and Color.Wrap(code, label)
end

-- Classification, reaction and forces sit directly under the level line.
local function applyLevelBlock(tooltip, unit, guid, db, numLines)
  local reaction = db.showReaction and reactionText(unit)
  local forces = db.showEnemyForces and FlavorCompat.hasMythicPlus and guid and EnemyForces.Line(guid)
  if not (db.showClassification or reaction or forces) then
    return
  end
  local levelIndex = Lines.FindLevel(numLines)
  local level = db.showClassification and classifiedLevel(unit) or (levelIndex and Lines.Text(levelIndex))
  count = 0
  push(level)
  push(reaction)
  push(forces and Color.Wrap(Color.GOLD, forces))
  local text = concat(parts, "\n", 1, count)
  if levelIndex then
    Lines.Set(levelIndex, text)
  elseif text ~= "" then
    tooltip:AddLine(text, 1, 1, 1)
  end
end

local function applyName(unit, db)
  local name = Secret.Clean(_G.UnitName(unit))
  if not name then
    return
  end
  local icon = db.showRaidIcon and UnitTags.RaidIcon(unit)
  local dead = db.showDeadTag and UnitTags.Dead(unit)
  if icon or dead then
    Lines.Set(1, (icon or "") .. name .. (dead or ""))
  end
end

local ownerPatterns
local function ownerOf(text)
  if not ownerPatterns then
    ownerPatterns = {}
    for _, key in ipairs(OWNER_FORMATS) do
      local fmt = _G[key]
      if type(fmt) == "string" then
        local escaped = gsub(fmt, "([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
        ownerPatterns[#ownerPatterns + 1] = "^" .. gsub(escaped, "%%s", "(.+)") .. "$"
      end
    end
  end
  for _, pattern in ipairs(ownerPatterns) do
    local owner = match(text, pattern)
    if owner then
      return owner
    end
  end
  return nil
end

local function applyOwner(numLines)
  for index = 2, math.min(numLines, OWNER_LINES_MAX) do
    local text = Lines.Text(index)
    local owner = text and ownerOf(text)
    if owner then
      Lines.Set(index, Color.Label(Localization.Text("Owner:")) .. " " .. owner)
      return
    end
  end
end

local function applyQuest(numLines)
  for index = 2, numLines do
    local text, done = Quest.Objective(Lines.Text(index))
    if done then
      Lines.left[index]:SetTextColor(DONE_R, DONE_G, DONE_B)
    elseif text then
      Lines.Set(index, text)
    end
  end
end

function NpcLines.Apply(tooltip, unit, guid, db)
  local numLines = tooltip:NumLines()
  if db.showRaidIcon or db.showDeadTag then
    applyName(unit, db)
  end
  if db.grayTapped and Secret.Clean(_G.UnitIsTapDenied(unit)) then
    Lines.left[1]:SetTextColor(TAPPED_GRAY, TAPPED_GRAY, TAPPED_GRAY)
  end
  applyLevelBlock(tooltip, unit, guid, db, numLines)
  if db.showPetOwner then
    applyOwner(numLines)
  end
  if db.showQuest then
    applyQuest(numLines)
  end
end

ns.NpcLines = NpcLines
return NpcLines
