local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Defaults = ns.SettingsDefaults or require("MouseOverTooltip.Settings.Defaults")

local SavedState = {}

-- Returns the account-wide settings table: saved values win, missing keys get
-- their default, keys no longer known are dropped so the file never grows.
function SavedState.Initialize(saved)
  saved = type(saved) == "table" and saved or {}
  local db = {}
  for _, entry in ipairs(Defaults.list) do
    if entry.key then
      local value = saved[entry.key]
      if type(value) == "boolean" then
        db[entry.key] = value
      else
        db[entry.key] = entry.default
      end
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
