local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")

local find = string.find
local format = string.format
local match = string.match
local tonumber = tonumber

local Quest = {}

-- Blizzard already prints quest titles and objectives on unit tooltips; we
-- only add "(n left)" and report completion so the caller can color it.
-- Returns newText, isDone — or nil when the line is not an open objective.
-- ponytail: "x/y" text match; tooltip data line types are Retail-only
function Quest.Objective(text)
  if type(text) ~= "string" then
    return nil
  end
  local done, total = match(text, "(%d+)/(%d+)")
  done, total = tonumber(done), tonumber(total)
  if not done or not total or total == 0 then
    return nil
  end
  if done >= total then
    return text, true
  end
  local suffix = format(Localization.Text("(%d left)"), total - done)
  if find(text, suffix, 1, true) then
    return nil
  end
  return text .. " " .. suffix, false
end

ns.Quest = Quest
return Quest
