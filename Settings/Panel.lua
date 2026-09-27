local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Defaults = ns.SettingsDefaults or require("MouseOverTooltip.Settings.Defaults")
local FlavorCompat = ns.FlavorCompat or require("MouseOverTooltip.Core.FlavorCompat")
local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")

local CATEGORY_NAME = "MouseOverTooltip"
local LEFT = 16
local COLUMN_WIDTH = 310
local TOP = -16
local TITLE_HEIGHT = 36
local HEADER_HEIGHT = 26
local ROW_HEIGHT = 22
local BOX_SIZE = 22
local LABEL_WIDTH = 250

-- Two-column canvas page in Options > AddOns, so every setting fits on one
-- screen. Widgets are built on first open; until then only the empty canvas
-- exists. The panel's Defaults button calls OnDefault.
local Panel = {}

local category
local boxes = {}

local function available(entry)
  return not entry.requires or FlavorCompat[entry.requires]
end

local function addText(frame, font, text, x, y)
  local label = frame:CreateFontString(nil, "ARTWORK", font)
  label:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
  label:SetJustifyH("LEFT")
  label:SetText(text)
  return label
end

local function addCheckbox(frame, entry, x, y, db, onChanged)
  local box = _G.CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  box:SetSize(BOX_SIZE, BOX_SIZE)
  box:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
  box:SetHitRectInsets(0, -LABEL_WIDTH, 0, 0)
  box.label = addText(frame, "GameFontHighlight", Localization.Text(entry.label), x + BOX_SIZE + 4, y - 5)
  box.label:SetWidth(LABEL_WIDTH)
  box:SetChecked(db[entry.key])
  local key = entry.key
  box:SetScript("OnClick", function(self)
    local value = self:GetChecked() and true or false
    db[key] = value
    onChanged(key, value)
  end)
  boxes[key] = box
end

local function build(frame, db, onChanged)
  addText(frame, "GameFontNormalLarge", CATEGORY_NAME, LEFT, TOP)
  local x, y = LEFT, TOP - TITLE_HEIGHT
  for _, entry in ipairs(Defaults.list) do
    if entry.column then
      x, y = LEFT + COLUMN_WIDTH, TOP - TITLE_HEIGHT
    elseif entry.header then
      addText(frame, "GameFontNormal", Localization.Text(entry.header), x, y - 8)
      y = y - HEADER_HEIGHT
    elseif available(entry) then
      addCheckbox(frame, entry, x, y, db, onChanged)
      y = y - ROW_HEIGHT
    end
  end
end

local function refresh(db)
  for key, box in pairs(boxes) do
    box:SetChecked(db[key])
  end
end

local function restoreDefaults(db, onChanged)
  for _, entry in ipairs(Defaults.list) do
    if entry.key and db[entry.key] ~= entry.default then
      db[entry.key] = entry.default
      onChanged(entry.key, entry.default)
    end
  end
  refresh(db)
end

function Panel.Register(db, onChanged)
  local settings = _G.Settings
  if not (settings and settings.RegisterCanvasLayoutCategory) then
    return nil
  end
  local frame = _G.CreateFrame("Frame")
  local built = false
  frame:SetScript("OnShow", function(self)
    if not built then
      built = true
      build(self, db, onChanged)
    end
    refresh(db)
  end)
  frame.OnCommit = function() end
  frame.OnRefresh = function()
    refresh(db)
  end
  frame.OnDefault = function()
    restoreDefaults(db, onChanged)
  end
  category = settings.RegisterCanvasLayoutCategory(frame, CATEGORY_NAME)
  settings.RegisterAddOnCategory(category)
  return category
end

function Panel.Open()
  if category then
    _G.Settings.OpenToCategory(category:GetID())
  end
end

ns.SettingsPanel = Panel
return Panel
