local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")

local floor = math.floor

local ROW_HEIGHT = 22
local BOX_SIZE = 22
local LABEL_WIDTH = 250
local SLIDER_TEMPLATE = "MinimalSliderWithSteppersTemplate"
local SLIDER_LABEL_WIDTH = 14
local SLIDER_WIDTH = 110
local FONT_ENABLED = "GameFontHighlight"
local FONT_DISABLED = "GameFontDisable"
local LABEL_GAP = 4
local LABEL_DROP = 5

-- Option-row builders for the options panel. AddCheckbox and AddSlider each
-- return the template frame itself with its label at `frame.label`.
local Widgets = {}

local function round(value)
  return floor(value + 0.5)
end

local function showHint(owner)
  local tooltip = _G.GameTooltip
  tooltip:SetOwner(owner, "ANCHOR_RIGHT")
  tooltip:SetText(owner.hint, nil, nil, nil, nil, true)
  tooltip:Show()
end

local function hideHint()
  _G.GameTooltip:Hide()
end

-- Button API: lets a grayed-out checkbox still show its hint on hover.
local function keepMotionScripts(widget)
  if widget.SetMotionScriptsWhileDisabled then
    widget:SetMotionScriptsWhileDisabled(true)
  end
end

local function attachHint(target, hint)
  target.hint = Localization.Text(hint)
  target:HookScript("OnEnter", showHint)
  target:HookScript("OnLeave", hideHint)
end

function Widgets.AddText(frame, font, text, x, y)
  local label = frame:CreateFontString(nil, "ARTWORK", font)
  label:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
  label:SetJustifyH("LEFT")
  label:SetText(text)
  return label
end

function Widgets.AddCheckbox(frame, entry, x, y, db, onChanged)
  local box = _G.CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  box:SetSize(BOX_SIZE, BOX_SIZE)
  box:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
  box:SetHitRectInsets(0, -LABEL_WIDTH, 0, 0)
  box.label = Widgets.AddText(frame, FONT_ENABLED, Localization.Text(entry.label), x + BOX_SIZE + LABEL_GAP, y - LABEL_DROP)
  box.label:SetWidth(LABEL_WIDTH)
  box:SetChecked(db[entry.key])
  attachHint(box, entry.hint)
  keepMotionScripts(box)
  local key = entry.key
  box:SetScript("OnClick", function(self)
    local value = self:GetChecked() and true or false
    db[key] = value
    onChanged(key, value)
  end)

  return box
end

-- Value shows in the template's right label; step count = range, so 1-unit steps.
function Widgets.AddSlider(frame, entry, x, y, db, onChanged)
  local mixin = _G.MinimalSliderWithSteppersMixin
  local slider = _G.CreateFrame("Frame", nil, frame, SLIDER_TEMPLATE)
  slider:SetSize(SLIDER_WIDTH, ROW_HEIGHT)
  slider:SetPoint("TOPLEFT", frame, "TOPLEFT", x + (entry.labelWidth or SLIDER_LABEL_WIDTH), y)
  slider.label = Widgets.AddText(frame, FONT_ENABLED, Localization.Text(entry.label), x, y - LABEL_DROP)
  local key = entry.key
  local suffix = entry.suffix or ""
  slider:Init(db[key], entry.min, entry.max, entry.max - entry.min, {
    [mixin.Label.Right] = function(value)
      return round(value) .. suffix
    end,
  })
  slider:RegisterCallback(mixin.Event.OnValueChanged, function(_owner, value)
    value = round(value)
    if db[key] ~= value then
      db[key] = value
      onChanged(key, value)
    end
  end, slider)
  attachHint(slider.Slider, entry.hint)

  return slider
end

function Widgets.SetEnabled(widget, enabled)
  if widget.SetEnabled then
    widget:SetEnabled(enabled)
  end
  local label = widget.label
  if label and label.SetFontObject then
    label:SetFontObject(enabled and FONT_ENABLED or FONT_DISABLED)
  end
end

ns.SettingsWidgets = Widgets
return Widgets
