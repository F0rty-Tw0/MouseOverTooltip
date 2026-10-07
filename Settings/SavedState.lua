local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Defaults = ns.SettingsDefaults or require("MouseOverTooltip.Settings.Defaults")

local floor, max, min = math.floor, math.max, math.min

local SavedState = {}

-- Numeric settings: whole numbers inside the entry's range; NaN and
-- non-numbers fall back to the default.
local function validValue(entry, value)
  if entry.min then
    if type(value) ~= "number" or value ~= value then
      return entry.default
    end
    return min(entry.max, max(entry.min, floor(value + 0.5)))
  end
  if type(value) == "boolean" then
    return value
  end
  return entry.default
end

-- Returns the account-wide settings table: saved values win, missing keys get
-- their default, keys no longer known are dropped so the file never grows.
function SavedState.Initialize(saved)
  saved = type(saved) == "table" and saved or {}
  local db = {}
  for _, entry in ipairs(Defaults.list) do
    if entry.key then
      db[entry.key] = validValue(entry, saved[entry.key])
    end
  end
  for key, default in pairs(Defaults.state) do
    local value = saved[key]
    db[key] = type(value) == type(default) and value or default
  end
  return db
end

ns.SavedState = SavedState
return SavedState
