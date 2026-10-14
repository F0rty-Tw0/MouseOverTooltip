local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Constants = ns.Constants or require("MouseOverTooltip.Core.Constants")
local Defaults = ns.SettingsDefaults or require("MouseOverTooltip.Settings.Defaults")
local FlavorCompat = ns.FlavorCompat or require("MouseOverTooltip.Core.FlavorCompat")
local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")
local Widgets = ns.SettingsWidgets or require("MouseOverTooltip.Settings.Widgets")

local CATEGORY_NAME = Constants.TITLE
local LEFT = 16
local COLUMN_WIDTH = 310
local TOP = -16
local TITLE_HEIGHT = 36
local TAB_WIDTH = 100
local TAB_HEIGHT = 24
local TAB_GAP = 4
local TAB_ROW_GAP = 12
local TAB_TOP = TOP - TITLE_HEIGHT
local CONTENT_TOP = TAB_TOP - TAB_HEIGHT - TAB_ROW_GAP
local HEADER_HEIGHT = 26
local HEADER_DROP = 8
local ROW_HEIGHT = 22
local SLIDER_ROW_HEIGHT = ROW_HEIGHT + 4
local SLIDER_HALF = 170
local INDENT = 20

-- Tabbed canvas page in Options > AddOns: a row of tab buttons under the
-- title, one child frame per tab, one tab shown at a time. Until first open
-- only the empty canvas exists; each tab builds its widgets the first time
-- it is selected. Reopening the panel keeps the tab that was last shown,
-- since OnShow only selects the first tab while the tabs are being made.
-- The panel's Defaults button calls OnDefault.
local Panel = {}

local category
local db, onChanged
local tabs -- { name, entries, frame, button, built } per tab, made on first open
local boxes = {}
local sliders = {}
local children = {} -- parent key -> child widgets, grayed out while the parent is off

local function available(entry)
  return not entry.requires or FlavorCompat[entry.requires]
end

local function applyChildren(parentKey)
  local enabled = db[parentKey] and true or false
  for _, widget in ipairs(children[parentKey]) do
    Widgets.SetEnabled(widget, enabled)
  end
end

local function applyAllChildren()
  for parentKey in pairs(children) do
    applyChildren(parentKey)
  end
end

-- Forwards to the panel's onChanged; a parent checkbox also re-gates its children.
local function notifyChanged(key, value)
  onChanged(key, value)
  if children[key] then
    applyChildren(key)
  end
end

local function addWidget(frame, entry, x, y)
  if not entry.min then
    boxes[entry.key] = Widgets.AddCheckbox(frame, entry, x, y, db, notifyChanged)
    return boxes[entry.key]
  end
  sliders[entry.key] = Widgets.AddSlider(frame, entry, x, y, db, notifyChanged)
  return sliders[entry.key]
end

local function registerChild(entry, widget)
  local siblings = children[entry.parent] or {}
  siblings[#siblings + 1] = widget
  children[entry.parent] = siblings
end

-- Returns the y below the added row; a `sameRow` slider sits beside the
-- previous one and leaves y alone. A child row is indented under its parent.
local function addSetting(frame, entry, x, y)
  local left = entry.parent and x + INDENT or x
  local sameRow = entry.min and entry.sameRow
  local widget = addWidget(frame, entry, sameRow and left + SLIDER_HALF or left, sameRow and y + SLIDER_ROW_HEIGHT or y)
  if entry.parent then
    registerChild(entry, widget)
  end
  if sameRow then
    return y
  end

  return y - (entry.min and SLIDER_ROW_HEIGHT or ROW_HEIGHT)
end

-- True when a row after `from` shows up before the next header or column.
local function sectionHasRows(entries, from)
  for i = from, #entries do
    local entry = entries[i]
    if entry.header or entry.column then
      return false
    end
    if available(entry) then
      return true
    end
  end
  return false
end

local function buildTab(tab)
  local frame = tab.frame
  local x, y = LEFT, CONTENT_TOP
  for index, entry in ipairs(tab.entries) do
    if entry.column then
      x, y = LEFT + COLUMN_WIDTH, CONTENT_TOP
    elseif entry.header then
      if sectionHasRows(tab.entries, index + 1) then
        Widgets.AddText(frame, "GameFontNormal", Localization.Text(entry.header), x, y - HEADER_DROP)
        y = y - HEADER_HEIGHT
      end
    elseif available(entry) then
      y = addSetting(frame, entry, x, y)
    end
  end
  tab.built = true
  applyAllChildren()
end

local function setHighlight(button, locked)
  if locked and button.LockHighlight then
    button:LockHighlight()
  elseif not locked and button.UnlockHighlight then
    button:UnlockHighlight()
  end
end

local function selectTab(index)
  local tab = tabs[index]
  if not tab.built then
    buildTab(tab)
  end
  for i, other in ipairs(tabs) do
    other.frame:SetShown(i == index)
    setHighlight(other.button, i == index)
  end
end

-- Each `tab` marker starts a record holding the entries up to the next one.
local function splitTabs()
  local list = {}
  for _, entry in ipairs(Defaults.list) do
    if entry.tab then
      list[#list + 1] = { name = entry.tab, entries = {}, built = false }
    else
      local entries = list[#list].entries
      entries[#entries + 1] = entry
    end
  end
  return list
end

local function addTabButton(canvas, tab, index)
  local button = _G.CreateFrame("Button", nil, canvas, "UIPanelButtonTemplate")
  button:SetSize(TAB_WIDTH, TAB_HEIGHT)
  button:SetPoint("TOPLEFT", canvas, "TOPLEFT", LEFT + (index - 1) * (TAB_WIDTH + TAB_GAP), TAB_TOP)
  button:SetText(Localization.Text(tab.name))
  button:SetScript("OnClick", function()
    selectTab(index)
  end)
  return button
end

local function createTabs(canvas)
  Widgets.AddText(canvas, "GameFontNormalLarge", CATEGORY_NAME, LEFT, TOP)
  tabs = splitTabs()
  for index, tab in ipairs(tabs) do
    tab.button = addTabButton(canvas, tab, index)
    tab.frame = _G.CreateFrame("Frame", nil, canvas)
    tab.frame:SetAllPoints(canvas)
    tab.frame:Hide()
  end
end

local function refresh()
  for key, box in pairs(boxes) do
    box:SetChecked(db[key])
  end
  for key, slider in pairs(sliders) do
    slider:SetValue(db[key])
  end
  applyAllChildren()
end

-- Walks the whole list, so settings on tabs never opened reset too.
local function restoreDefaults()
  for _, entry in ipairs(Defaults.list) do
    if entry.key and db[entry.key] ~= entry.default then
      db[entry.key] = entry.default
      onChanged(entry.key, entry.default)
    end
  end
  refresh()
end

function Panel.Register(savedDb, changedCallback)
  local settings = _G.Settings
  if not (settings and settings.RegisterCanvasLayoutCategory) then
    return nil
  end
  db, onChanged = savedDb, changedCallback
  local frame = _G.CreateFrame("Frame")
  frame:SetScript("OnShow", function(self)
    if not tabs then
      createTabs(self)
      selectTab(1)
    end
    refresh()
  end)
  frame.OnCommit = function() end
  frame.OnRefresh = refresh
  frame.OnDefault = restoreDefaults
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
