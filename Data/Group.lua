local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Color = ns.Color or require("MouseOverTooltip.Core.Color")
local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")
local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local concat = table.concat

local MAX_RAID = 40
local MAX_PARTY = 4

local Group = {}

-- Unit tokens built once so hovering never concatenates them.
local raidUnits, raidTargets, partyUnits, partyTargets = {}, {}, {}, {}
for i = 1, MAX_RAID do
  raidUnits[i] = "raid" .. i
  raidTargets[i] = "raid" .. i .. "target"
end
for i = 1, MAX_PARTY do
  partyUnits[i] = "party" .. i
  partyTargets[i] = "party" .. i .. "target"
end
local targetTokens = setmetatable({}, {
  __index = function(tokens, unit)
    local token = unit .. "target"
    tokens[unit] = token
    return token
  end,
})

local function coloredName(unit)
  local name = Secret.Clean(_G.UnitName(unit))
  if not name then
    return nil
  end
  local code = Color.Unit(unit)
  return code and Color.Wrap(code, name) or name
end

-- "<<YOU>>" when the unit targets you, else the colored target name.
function Group.Target(unit)
  local target = targetTokens[unit]
  if not Secret.Clean(_G.UnitExists(target)) then
    return nil
  end
  if Secret.Clean(_G.UnitIsUnit(target, "player")) then
    return Color.Wrap(Color.RED, Localization.Text("<<YOU>>"))
  end
  return coloredName(target)
end

local names = {}
local count = 0

local function collect(member, memberTarget, unit)
  if Secret.Clean(_G.UnitIsUnit(memberTarget, unit)) and not Secret.Clean(_G.UnitIsUnit(member, "player")) then
    local name = coloredName(member)
    if name then
      count = count + 1
      names[count] = name
    end
  end
end

-- Comma list of group members (not you) targeting the unit; nil when none.
function Group.TargetedBy(unit)
  local size = _G.GetNumGroupMembers()
  if size == 0 then
    return nil
  end
  count = 0
  if _G.IsInRaid() then
    for i = 1, math.min(size, MAX_RAID) do
      collect(raidUnits[i], raidTargets[i], unit)
    end
  else
    for i = 1, math.min(size - 1, MAX_PARTY) do
      collect(partyUnits[i], partyTargets[i], unit)
    end
  end
  if count == 0 then
    return nil
  end
  return concat(names, ", ", 1, count)
end

ns.Group = Group
return Group
