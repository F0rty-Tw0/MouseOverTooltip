local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Color = ns.Color or require("MouseOverTooltip.Core.Color")
local Friends = ns.Friends or require("MouseOverTooltip.Data.Friends")
local Lines = ns.TooltipLines or require("MouseOverTooltip.Tooltip.Lines")
local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")
local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")
local UnitTags = ns.UnitTags or require("MouseOverTooltip.Tooltip.UnitTags")

local concat = table.concat
local find = string.find
local gsub = string.gsub
local sub = string.sub
local tostring = tostring

local FACTION_CODES = { Alliance = "|cff4a54e8", Horde = "|cffe50d12" }
local GUILD_CODE = "|cff8cb4ff"
local MY_GUILD_CODE = "|cff40ff40"

-- Rewrites Blizzard's player header (name, guild, level lines) into:
--   {icon} Name - Title <AFK> <Dead> (Friend)
--   <Guild> - Rank
--   Realm
--   80 Human Frost Mage (Alliance)
local PlayerHeader = {}

local parts = {}
local count = 0
local function push(text)
  count = count + 1
  parts[count] = text
end
local function flush(separator)
  local text = concat(parts, separator, 1, count)
  count = 0
  return text
end

local function titleOf(unit, name)
  local pvpName = Secret.Clean(_G.UnitPVPName(unit))
  if not pvpName then
    return nil
  end
  local first, last = find(pvpName, name, 1, true)
  if not first then
    return nil
  end
  local title = sub(pvpName, 1, first - 1) .. sub(pvpName, last + 1)
  title = gsub(gsub(title, "^[%s,]+", ""), "[%s,]+$", "")
  return title ~= "" and title or nil
end

local function statusTag(unit)
  local connected = _G.UnitIsConnected(unit)
  if not Secret.Is(connected) and not connected then
    return Localization.Text("Offline")
  end
  if Secret.Clean(_G.UnitIsAFK(unit)) then
    return Localization.Text("AFK")
  end
  if Secret.Clean(_G.UnitIsDND(unit)) then
    return Localization.Text("DND")
  end
  return nil
end

-- Name line; returns the realm for cross-realm players (nil otherwise).
function PlayerHeader.Name(unit, guid, db, classCode)
  local name, realm = Secret.Clean2(_G.UnitName(unit))
  if not name then
    return nil
  end
  if db.showTitle then
    local title = titleOf(unit, name)
    name = title and (name .. " - " .. title) or name
  end
  count = 0
  local icon = db.showRaidIcon and UnitTags.RaidIcon(unit)
  if icon then
    push(icon)
  end
  push(classCode and Color.Wrap(classCode, name) or name)
  local status = db.showRealmStatus and statusTag(unit)
  if status then
    push(" " .. Color.Wrap(Color.GRAY, "<" .. status .. ">"))
  end
  local dead = db.showDeadTag and UnitTags.Dead(unit)
  if dead then
    push(dead)
  end
  local friend = db.showFriend and guid and Friends.Tag(guid)
  if friend then
    push(" " .. friend)
  end
  Lines.Set(1, flush(""))
  return realm ~= "" and realm or nil
end

function PlayerHeader.Guild(unit, db)
  local guild, rank = _G.GetGuildInfo(unit)
  guild, rank = Secret.Clean(guild), Secret.Clean(rank)
  if not guild then
    return nil
  end
  local code = GUILD_CODE
  if db.highlightMyGuild and guild == Secret.Clean((_G.GetGuildInfo("player"))) then
    code = MY_GUILD_CODE
  end
  local text = "<" .. guild .. ">"
  if rank then
    text = text .. " - " .. rank
  end
  return Color.Wrap(code, text)
end

local function pushFaction(unit)
  local faction, localized = _G.UnitFactionGroup(unit)
  faction, localized = Secret.Clean(faction), Secret.Clean(localized)
  if faction and FACTION_CODES[faction] and localized then
    push(Color.Wrap(FACTION_CODES[faction], "(" .. localized .. ")"))
  end
end

-- "80 Human Frost Mage (Alliance)" from the enabled parts only; "" when none
-- is enabled, nil when the level is secret (caller keeps Blizzard's line).
function PlayerHeader.Level(unit, db, classCode, className, specName)
  count = 0
  if db.showLevel then
    local level = _G.UnitLevel(unit)
    if Secret.Is(level) or type(level) ~= "number" then
      return nil
    end
    push(Color.Wrap(Color.Difficulty(unit, level), level > 0 and tostring(level) or "??"))
  end
  local race = db.showRace and Secret.Clean(_G.UnitRace(unit))
  if race then
    push(race)
  end
  if specName then
    push(specName)
  end
  if db.showClass and className then
    push(classCode and Color.Wrap(classCode, className) or className)
  end
  if db.showFaction then
    pushFaction(unit)
  end
  return flush(" ")
end

function PlayerHeader.Wanted(db)
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

local noise
local suffixClass, classSuffix
-- Blizzard's faction, PvP and "Spec Class" lines, which the level line replaces.
function PlayerHeader.IsNoise(text, className)
  if not noise then
    noise = {}
    for _, key in ipairs({ "FACTION_ALLIANCE", "FACTION_HORDE", "FACTION_NEUTRAL", "PVP", "PVP_ENABLED" }) do
      if _G[key] then
        noise[_G[key]] = true
      end
    end
  end
  if noise[text] or text == className then
    return true
  end
  if not className then
    return false
  end
  if className ~= suffixClass then
    suffixClass, classSuffix = className, " " .. className
  end
  return sub(text, -#classSuffix) == classSuffix
end

-- Clears noise lines under the level line.
-- Appends the cleared indexes to `freed` after `freedCount`; returns the new count.
function PlayerHeader.ClearNoise(fromIndex, numLines, className, freed, freedCount)
  for index = fromIndex, numLines do
    local text = Lines.Text(index)
    if text and PlayerHeader.IsNoise(text, className) then
      Lines.Set(index, nil)
      freedCount = freedCount + 1
      freed[freedCount] = index
    end
  end
  return freedCount
end

ns.PlayerHeader = PlayerHeader
return PlayerHeader
