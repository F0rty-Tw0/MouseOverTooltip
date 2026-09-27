local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local find = string.find
local gsub = string.gsub

-- GameTooltip's left-column font strings, looked up once per index.
local Lines = {}

local left = setmetatable({}, {
  __index = function(cache, index)
    local line = _G["GameTooltipTextLeft" .. index]
    if line then
      cache[index] = line
    end
    return line
  end,
})
Lines.left = left

function Lines.Text(index)
  local line = left[index]
  return line and Secret.Clean(line:GetText())
end

function Lines.Set(index, text)
  local line = left[index]
  if line then
    line:SetText(text)
  end
end

-- "Level %s" -> "^Level .+"; built on first use so locale globals exist.
local levelPattern
function Lines.IsLevel(text)
  if not levelPattern then
    levelPattern = "^" .. gsub(_G.TOOLTIP_UNIT_LEVEL or "Level %s", "%%s", ".+")
  end
  return find(text, levelPattern) ~= nil
end

function Lines.FindLevel(numLines)
  for index = 2, numLines do
    local text = Lines.Text(index)
    if text and Lines.IsLevel(text) then
      return index
    end
  end
  return nil
end

ns.TooltipLines = Lines
return Lines
