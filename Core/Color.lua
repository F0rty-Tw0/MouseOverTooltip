local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local format = string.format
local floor = math.floor

local Color = {}

local function byte(value)
  return floor((value or 1) * 255 + 0.5)
end

function Color.Code(r, g, b)
  return format("|cff%02x%02x%02x", byte(r), byte(g), byte(b))
end

function Color.FromTable(color)
  if type(color) ~= "table" then
    return nil
  end
  return Color.Code(color.r, color.g, color.b)
end

function Color.Wrap(code, text)
  return code .. text .. "|r"
end

-- Gold "Label:" prefix shared by every added line.
function Color.Label(text)
  return "|cffffd100" .. text .. "|r"
end

-- Class colors never change in a session; build each escape code once.
local classCodes = {}
function Color.Class(classFile)
  if classFile == nil then
    return nil
  end
  local code = classCodes[classFile]
  if not code then
    local colors = _G.RAID_CLASS_COLORS
    code = colors and Color.FromTable(colors[classFile])
    classCodes[classFile] = code
  end
  return code
end

local reactionCodes = {}
function Color.Reaction(reaction)
  if reaction == nil then
    return nil
  end
  local code = reactionCodes[reaction]
  if not code then
    local colors = _G.FACTION_BAR_COLORS
    code = colors and Color.FromTable(colors[reaction])
    reactionCodes[reaction] = code
  end
  return code
end

-- Class color for players, reaction color for everything else.
function Color.Unit(unit)
  if Secret.Clean(_G.UnitIsPlayer(unit)) then
    local _, classFile = _G.UnitClass(unit)
    return Color.Class(Secret.Clean(classFile))
  end
  return Color.Reaction(Secret.Clean(_G.UnitReaction(unit, "player")))
end

-- Level color relative to the player, like Blizzard's level text.
function Color.Difficulty(unit, level)
  -- Skull (-1) falls into the wrong bucket in Blizzard's tables.
  if level <= 0 then
    return Color.RED
  end
  local info = _G.C_PlayerInfo
  local color
  if info and info.GetContentDifficultyCreatureForPlayer and _G.GetDifficultyColor then
    color = _G.GetDifficultyColor(info.GetContentDifficultyCreatureForPlayer(unit))
  elseif _G.GetCreatureDifficultyColor then
    color = _G.GetCreatureDifficultyColor(level)
  elseif _G.GetQuestDifficultyColor then
    color = _G.GetQuestDifficultyColor(level)
  end
  return Color.FromTable(color) or Color.WHITE
end

Color.WHITE = "|cffffffff"
Color.GRAY = "|cff808080"
Color.GOLD = "|cffffd100"
Color.GREEN = "|cff20ff20"
Color.RED = "|cffff2020"
Color.LIGHT = "|cffcccccc"
Color.EPIC = "|cffa335ee"

ns.Color = Color
return Color
