-- Minimal fake WoW API. Wow.Install() rebuilds every global from scratch and
-- returns the state table `W`; tests drive units, combat, time and timers
-- through it. W.calls[name] counts calls to any API defined with def().

local Wow = {}

local NOOP_METHODS = {
  "SetSize",
  "SetHitRectInsets",
  "SetWidth",
  "SetHeight",
  "ClearAllPoints",
  "SetAllPoints",
  "SetFrameStrata",
  "SetFrameLevel",
  "EnableMouse",
  "RegisterForDrag",
  "RegisterForClicks",
  "SetMovable",
  "SetClampedToScreen",
  "StartMoving",
  "StopMovingOrSizing",
  "SetTexture",
  "SetTexCoord",
  "SetVertexColor",
  "SetDrawLayer",
  "SetFontObject",
  "SetJustifyH",
  "SetParent",
  "SetHighlightTexture",
  "SetNormalTexture",
  "SetUserPlaced",
}

local function newWidget(W, name)
  local widget = { scripts = {}, hooks = {}, events = {}, shown = true, name = name }
  for _, method in ipairs(NOOP_METHODS) do
    widget[method] = function() end
  end
  function widget:SetPoint(...)
    self.point = { ... }
  end
  function widget:SetChecked(checked)
    self.checked = checked and true or false
  end
  function widget:GetChecked()
    return self.checked
  end
  function widget:SetScript(script, fn)
    self.scripts[script] = fn
  end
  function widget:GetScript(script)
    return self.scripts[script]
  end
  function widget:HookScript(script, fn)
    self.hooks[script] = self.hooks[script] or {}
    table.insert(self.hooks[script], fn)
  end
  function widget:HasScript(script)
    return W.scriptSupport[script] == true
  end
  function widget:Fire(script, ...)
    if self.scripts[script] then
      self.scripts[script](self, ...)
    end
    for _, fn in ipairs(self.hooks[script] or {}) do
      fn(self, ...)
    end
  end
  function widget:RegisterEvent(event)
    self.events[event] = true
  end
  function widget:UnregisterEvent(event)
    self.events[event] = nil
  end
  function widget:FireEvent(event, ...)
    if self.events[event] and self.scripts.OnEvent then
      self.scripts.OnEvent(self, event, ...)
    end
  end
  function widget:Show()
    self.shown = true
  end
  function widget:Hide()
    self.shown = false
  end
  function widget:SetShown(shown)
    self.shown = shown and true or false
  end
  function widget:IsShown()
    return self.shown
  end
  function widget:SetText(text)
    self.text = text
  end
  function widget:GetText()
    return self.text
  end
  function widget:SetTextColor(r, g, b)
    self.color = { r, g, b }
  end
  function widget:GetCenter()
    return self.centerX or 0, self.centerY or 0
  end
  function widget:GetEffectiveScale()
    return 1
  end
  function widget:CreateTexture()
    return newWidget(W)
  end
  function widget:CreateFontString()
    return newWidget(W)
  end
  if name then
    rawset(_G, name, widget)
  end
  table.insert(W.frames, widget)
  return widget
end

local function installTooltip(W)
  local tip = newWidget(W, "GameTooltip")
  tip.shown = false
  tip.numLines = 0
  tip.NineSlice = newWidget(W)
  function tip.NineSlice:SetBorderColor(r, g, b)
    tip.borderColor = { r, g, b }
  end
  function tip:NumLines()
    return self.numLines
  end
  function tip:AddLine(text, r, g, b)
    self.numLines = self.numLines + 1
    local line = W.Line(self.numLines)
    line.text = text
    line.color = { r, g, b }
  end
  function tip:ClearLines()
    for i = 1, self.numLines do
      W.Line(i).text = nil
    end
    self.numLines = 0
  end
  function tip:GetUnit()
    return W.tooltipUnit and W.units[W.tooltipUnit] and W.units[W.tooltipUnit].name, W.tooltipUnit
  end
  function tip:GetItem()
    return W.tooltipItemName, W.tooltipItemLink
  end
  function tip:SetOwner(owner, anchor)
    self.owner, self.anchor = owner, anchor
  end
  function tip:GetOwner()
    return self.owner
  end
  function tip:RefreshData()
    W.calls.RefreshData = (W.calls.RefreshData or 0) + 1
  end
  function tip:SetUnit(unit)
    W.calls.SetUnit = (W.calls.SetUnit or 0) + 1
    W.tooltipUnit = unit
  end
  W.tooltip = tip
  newWidget(W, "GameTooltipStatusBar")
end

function Wow.Install()
  local W = { units = {}, calls = {}, frames = {}, timers = {}, lines = {}, now = 100, scriptSupport = {} }

  local function def(name, fn)
    rawset(_G, name, function(...)
      W.calls[name] = (W.calls[name] or 0) + 1
      return fn(...)
    end)
  end
  W.def = def

  function W.Line(i)
    if not W.lines[i] then
      W.lines[i] = newWidget(W, "GameTooltipTextLeft" .. i)
    end
    return W.lines[i]
  end

  -- Replace the tooltip content with plain lines, like Blizzard's SetUnit.
  function W.SetTooltipLines(unit, texts)
    W.tooltip:ClearLines()
    W.tooltipUnit = unit
    for _, text in ipairs(texts) do
      W.tooltip:AddLine(text)
    end
    W.tooltip.shown = true
  end

  function W.LineText(i)
    return W.lines[i] and W.lines[i].text
  end

  function W.AllText()
    local parts = {}
    for i = 1, W.tooltip.numLines do
      parts[#parts + 1] = W.LineText(i) or ""
    end
    return table.concat(parts, "\n")
  end

  -- Runs every queued timer, advancing the clock past the longest delay.
  function W.RunTimers()
    local due = W.timers
    W.timers = {}
    local longest = 0
    for _, timer in ipairs(due) do
      longest = math.max(longest, timer.delay)
    end
    W.now = W.now + longest
    for _, timer in ipairs(due) do
      timer.fn()
    end
  end

  local function unit(token)
    return token and W.units[token]
  end

  rawset(_G, "WOW_PROJECT_ID", 1)
  rawset(_G, "WOW_PROJECT_MAINLINE", 1)
  rawset(_G, "TOOLTIP_UNIT_LEVEL", "Level %s")
  rawset(_G, "FACTION_ALLIANCE", "Alliance")
  rawset(_G, "FACTION_HORDE", "Horde")
  rawset(_G, "PVP", "PvP")
  rawset(_G, "RAID_CLASS_COLORS", { MAGE = { r = 0.25, g = 0.78, b = 0.92 }, WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } })
  rawset(_G, "FACTION_BAR_COLORS", { [2] = { r = 1, g = 0, b = 0 }, [4] = { r = 1, g = 1, b = 0 }, [5] = { r = 0, g = 1, b = 0 } })
  rawset(_G, "issecretvalue", nil)
  rawset(_G, "C_Timer", {
    After = function(delay, fn)
      table.insert(W.timers, { delay = delay, fn = fn })
    end,
  })

  def("CreateFrame", function(_frameType, name)
    return newWidget(W, name)
  end)
  def("hooksecurefunc", function(target, name, hook)
    if type(target) == "string" then
      target, name, hook = _G, target, name
    end
    local original = target[name]
    target[name] = function(...)
      local results = { original(...) }
      hook(...)
      return (table.unpack or unpack)(results)
    end
  end)
  def("GetTime", function()
    return W.now
  end)
  def("InCombatLockdown", function()
    return W.inCombat == true
  end)
  def("IsShiftKeyDown", function()
    return W.shiftDown == true
  end)
  def("GetNumGroupMembers", function()
    return W.groupSize or 0
  end)
  def("IsInRaid", function()
    return W.inRaid == true
  end)

  def("UnitExists", function(token)
    return unit(token) ~= nil
  end)
  def("UnitGUID", function(token)
    return unit(token) and unit(token).guid
  end)
  def("UnitName", function(token)
    local u = unit(token)
    if u then
      return u.name, u.realm
    end
  end)
  def("UnitIsUnit", function(a, b)
    return unit(a) ~= nil and unit(a) == unit(b)
  end)
  def("UnitIsPlayer", function(token)
    return unit(token) and unit(token).isPlayer == true
  end)
  def("UnitPlayerControlled", function(token)
    return unit(token) and (unit(token).isPlayer or unit(token).playerControlled) == true
  end)
  def("UnitClass", function(token)
    local u = unit(token)
    if u then
      return u.className, u.classFile
    end
  end)
  def("UnitRace", function(token)
    return unit(token) and unit(token).race
  end)
  def("UnitLevel", function(token)
    return unit(token) and unit(token).level or 1
  end)
  def("UnitFactionGroup", function(token)
    local u = unit(token)
    if u and u.faction then
      return u.faction, u.faction
    end
  end)
  def("UnitReaction", function(token)
    return unit(token) and unit(token).reaction
  end)
  def("UnitClassification", function(token)
    return unit(token) and unit(token).classification or "normal"
  end)
  def("UnitCreatureType", function(token)
    return unit(token) and unit(token).creatureType
  end)
  def("UnitIsDead", function(token)
    return unit(token) and unit(token).dead == true
  end)
  def("UnitIsGhost", function(token)
    return unit(token) and unit(token).ghost == true
  end)
  def("UnitIsTapDenied", function(token)
    return unit(token) and unit(token).tapDenied == true
  end)
  def("UnitIsAFK", function(token)
    return unit(token) and unit(token).afk == true
  end)
  def("UnitIsDND", function(token)
    return unit(token) and unit(token).dnd == true
  end)
  def("UnitIsConnected", function(token)
    return unit(token) and unit(token).offline ~= true
  end)
  def("UnitPVPName", function(token)
    return unit(token) and (unit(token).pvpName or unit(token).name)
  end)
  def("GetGuildInfo", function(token)
    local g = unit(token) and unit(token).guild
    if g then
      return g.name, g.rank, 1, g.realm
    end
  end)
  def("GetRaidTargetIndex", function(token)
    return unit(token) and unit(token).raidIcon
  end)
  def("CanInspect", function(token)
    return unit(token) ~= nil and unit(token).isPlayer == true
  end)
  def("NotifyInspect", function(token)
    W.lastInspect = token
  end)
  def("ClearInspectPlayer", function() end)

  newWidget(W, "UIParent")
  newWidget(W, "Minimap")
  installTooltip(W)
  return W
end

return Wow
