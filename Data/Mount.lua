local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Color = ns.Color or require("MouseOverTooltip.Core.Color")
local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")
local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local gsub = string.gsub
local pcall = pcall

local MAX_AURAS = 40
local ICON_COLLECTED = " |TInterface\\RaidFrame\\ReadyCheck-Ready:0|t"
local ICON_MISSING = " |TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t"

local Mount = {}

-- Classic without C_UnitAuras falls back to UnitAura's 10th return.
local function auraSpellId(unit, index)
  local auras = _G.C_UnitAuras
  if auras and auras.GetAuraDataByIndex then
    local ok, aura = pcall(auras.GetAuraDataByIndex, unit, index, "HELPFUL")
    if not ok then
      return nil, true
    end
    return aura and aura.spellId, aura == nil
  end
  local name, _, _, _, _, _, _, _, _, spellId = _G.UnitAura(unit, index, "HELPFUL")
  return spellId, name == nil
end

local function findMountId(unit)
  local journal = _G.C_MountJournal
  for index = 1, MAX_AURAS do
    local spellId, done = auraSpellId(unit, index)
    if done then
      return nil
    end
    spellId = Secret.Clean(spellId)
    local mountId = spellId and journal.GetMountFromSpell(spellId)
    if mountId then
      return mountId
    end
  end
  return nil
end

local function cleanSource(source)
  if type(source) ~= "string" or source == "" then
    return nil
  end
  source = gsub(source, "|n", " ")
  source = gsub(source, "|c%x%x%x%x%x%x%x%x", "")
  return (gsub(source, "|r", ""))
end

-- Returns "Mount: {icon} Name ✓" and, when enabled and uncollected, the
-- plain source text for a second line. nil = not mounted (or filtered out).
function Mount.Line(unit, db)
  local mountId = findMountId(unit)
  if not mountId then
    return nil
  end
  local journal = _G.C_MountJournal
  local name, _, icon, _, _, _, _, _, _, _, isCollected = journal.GetMountInfoByID(mountId)
  if not name or (db.mountOnlyUncollected and isCollected) then
    return nil
  end
  local text = Color.Label(Localization.Text("Mount:")) .. " "
  if db.showMountIcon and icon then
    text = text .. "|T" .. icon .. ":0|t "
  end
  text = text .. name .. (isCollected and ICON_COLLECTED or ICON_MISSING)
  local source
  if db.showMountSource and not isCollected then
    local _, _, sourceText = journal.GetMountInfoExtraByID(mountId)
    source = cleanSource(sourceText)
  end
  return text, source
end

ns.Mount = Mount
return Mount
