local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Constants = ns.Constants or require("MouseOverTooltip.Core.Constants")
local Defaults = ns.SettingsDefaults or require("MouseOverTooltip.Settings.Defaults")
local FlavorCompat = ns.FlavorCompat or require("MouseOverTooltip.Core.FlavorCompat")
local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")

local floor = math.floor

local CATEGORY_NAME = Constants.TITLE
local LEFT = 16
local COLUMN_WIDTH = 310
local TOP = -16
local TITLE_HEIGHT = 36
local HEADER_HEIGHT = 26
local ROW_HEIGHT = 22
local BOX_SIZE = 22
local LABEL_WIDTH = 250
local SLIDER_TEMPLATE = "MinimalSliderWithSteppersTemplate"
local SLIDER_ROW_HEIGHT = ROW_HEIGHT + 4
local SLIDER_LABEL_WIDTH = 14
local SLIDER_WIDTH = 110
local SLIDER_HALF = 170

-- Two-column canvas page in Options > AddOns, so every setting fits on one
-- screen. Widgets are built on first open; until then only the empty canvas
-- exists. The panel's Defaults button calls OnDefault.
local Panel = {}

local category
local boxes = {}
local sliders = {}

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

local function round(value)
  return floor(value + 0.5)
end

local function showHint(track)
  local tooltip = _G.GameTooltip
  tooltip:SetOwner(track, "ANCHOR_RIGHT")
  tooltip:SetText(track.hint)
  tooltip:Show()
end

local function hideHint()
  _G.GameTooltip:Hide()
end

-- Value shows in the template's right label; step count = range, so 1 px steps.
local function addSlider(frame, entry, x, y, db, onChanged)
  local mixin = _G.MinimalSliderWithSteppersMixin
  local slider = _G.CreateFrame("Frame", nil, frame, SLIDER_TEMPLATE)
  slider:SetSize(SLIDER_WIDTH, ROW_HEIGHT)
  slider:SetPoint("TOPLEFT", frame, "TOPLEFT", x + SLIDER_LABEL_WIDTH, y)
  slider.label = addText(frame, "GameFontHighlight", Localization.Text(entry.label), x, y - 5)
  local key = entry.key
  slider:Init(db[key], entry.min, entry.max, entry.max - entry.min, {
    [mixin.Label.Right] = function(value)
      return tostring(round(value))
    end,
  })
  slider:RegisterCallback(mixin.Event.OnValueChanged, function(_owner, value)
    value = round(value)
    if db[key] ~= value then
      db[key] = value
      onChanged(key, value)
    end
  end, slider)
  slider.Slider.hint = Localization.Text(entry.hint)
  slider.Slider:HookScript("OnEnter", showHint)
  slider.Slider:HookScript("OnLeave", hideHint)
  sliders[key] = slider
end

-- Returns the y below the added row; a `sameRow` slider sits beside the
-- previous one and leaves y alone.
local function addSetting(frame, entry, x, y, db, onChanged)
  if not entry.min then
    addCheckbox(frame, entry, x, y, db, onChanged)
    return y - ROW_HEIGHT
  end
  if entry.sameRow then
    addSlider(frame, entry, x + SLIDER_HALF, y + SLIDER_ROW_HEIGHT, db, onChanged)
    return y
  end
  addSlider(frame, entry, x, y, db, onChanged)
  return y - SLIDER_ROW_HEIGHT
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
      y = addSetting(frame, entry, x, y, db, onChanged)
    end
  end
end

local function refresh(db)
  for key, box in pairs(boxes) do
    box:SetChecked(db[key])
  end
  for key, slider in pairs(sliders) do
    slider:SetValue(db[key])
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
