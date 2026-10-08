local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Constants = ns.Constants or require("MouseOverTooltip.Core.Constants")
local FlavorCompat = ns.FlavorCompat or require("MouseOverTooltip.Core.FlavorCompat")
local Secret = ns.Secret or require("MouseOverTooltip.Core.Secret")

local floor = math.floor

local CACHE_MAX = Constants.INSPECT_CACHE_MAX
local CACHE_TTL = Constants.INSPECT_CACHE_TTL
local THROTTLE = Constants.INSPECT_THROTTLE
local TIMEOUT = Constants.INSPECT_TIMEOUT
local HOVER_DELAY = Constants.INSPECT_HOVER_DELAY

-- One inspect in flight at a time; the newest hover replaces the queued one.
-- INSPECT_READY is registered only while a request is pending.
local InspectCache = {}

local cache = {}
local cacheCount = 0
local deps = {}
local frame
local inflightUnit, inflightGuid
local queuedUnit, queuedGuid
local queuedAt = 0
local waiting = false
-- Timed out: not retried until another player is hovered, or every tooltip
-- rebuild would re-request it.
local failedGuid
local timerQueued = false
local lastNotify = -math.huge

function InspectCache.Configure(options)
  deps = options or {}
end

function InspectCache.Count()
  return cacheCount
end

function InspectCache.IsPending(guid)
  return guid ~= nil and (guid == inflightGuid or guid == queuedGuid)
end

function InspectCache.Get(guid)
  local entry = cache[guid]
  if entry and _G.GetTime() - entry.time <= CACHE_TTL then
    return entry
  end
  return nil
end

-- ponytail: O(n) oldest scan on insert only, n <= 100
local function evictOldest()
  local oldestGuid, oldestTime
  for guid, entry in pairs(cache) do
    if not oldestTime or entry.time < oldestTime then
      oldestGuid, oldestTime = guid, entry.time
    end
  end
  cache[oldestGuid] = nil
  cacheCount = cacheCount - 1
end

local function store(guid, ilvl, specID)
  local entry = cache[guid]
  if not entry then
    if cacheCount >= CACHE_MAX then
      evictOldest()
    end
    entry = {}
    cache[guid] = entry
    cacheCount = cacheCount + 1
  end
  entry.ilvl = ilvl and ilvl > 0 and floor(ilvl) or nil
  entry.specID = specID and specID > 0 and specID or nil
  entry.pvpRating, entry.pvpBracket = nil, nil
  entry.time = _G.GetTime()
end

local function readUnit(unit, guid, isSelf)
  local ilvl, specID
  if isSelf then
    if type(_G.GetAverageItemLevel) == "function" then
      ilvl = select(2, _G.GetAverageItemLevel())
    end
    if type(_G.GetSpecialization) == "function" and type(_G.GetSpecializationInfo) == "function" then
      local index = _G.GetSpecialization()
      specID = index and _G.GetSpecializationInfo(index)
    end
  else
    if FlavorCompat.hasItemLevel then
      ilvl = Secret.Clean(_G.C_PaperDollInfo.GetInspectItemLevel(unit))
    end
    if FlavorCompat.hasSpec then
      -- The global is a deprecated shim since 12.1.0.
      local specInfo = _G.C_SpecializationInfo
      local getSpec = specInfo and specInfo.GetInspectSpecialization or _G.GetInspectSpecialization
      specID = Secret.Clean(getSpec(unit))
    end
  end
  store(guid, ilvl, specID)
end

local schedule

local function finish()
  frame:UnregisterEvent("INSPECT_READY")
  local inspectFrame = _G.InspectFrame
  if not (inspectFrame and inspectFrame:IsShown()) then
    _G.ClearInspectPlayer()
  end
  inflightUnit, inflightGuid = nil, nil
  waiting = false
  if queuedGuid then
    schedule()
  end
end

local function unitStillMatches(unit, guid)
  local current = Secret.Clean(_G.UnitGUID(unit))
  return current ~= nil and current == guid
end

-- The hovered unit token may point elsewhere by the time data arrives.
local function resolveUnit(unit, guid)
  if unitStillMatches(unit, guid) then
    return unit
  end
  return _G.UnitTokenFromGUID and Secret.Clean(_G.UnitTokenFromGUID(guid))
end

local function notifyReady(guid)
  if deps.onReady then
    deps.onReady(guid)
  end
end

-- Retail PvP ratings arrive with the inspect data (no honor request there).
local function onEvent(_, _event, guid)
  if not waiting or Secret.Is(guid) or guid ~= inflightGuid then
    return
  end
  local unit = resolveUnit(inflightUnit, guid)
  if unit then
    readUnit(unit, guid, false)
    local entry = cache[guid]
    if deps.wantsPvp and deps.wantsPvp() and deps.readPvp then
      entry.pvpRating, entry.pvpBracket = deps.readPvp()
    end
  end
  finish()
  if unit then
    notifyReady(guid)
  end
end

local function onTimeout()
  if waiting and _G.GetTime() - lastNotify >= TIMEOUT then
    local guid = inflightGuid
    finish()
    failedGuid = guid
    notifyReady(guid)
  end
end

local function sendQueued()
  local unit, guid = queuedUnit, queuedGuid
  queuedUnit, queuedGuid = nil, nil
  if not (unitStillMatches(unit, guid) and _G.CanInspect(unit)) then
    notifyReady(guid)
    return
  end
  if not frame then
    frame = _G.CreateFrame("Frame")
    frame:SetScript("OnEvent", onEvent)
  end
  inflightUnit, inflightGuid = unit, guid
  waiting = true
  lastNotify = _G.GetTime()
  frame:RegisterEvent("INSPECT_READY")
  _G.NotifyInspect(unit)
  _G.C_Timer.After(TIMEOUT, onTimeout)
end

local function onTimer()
  timerQueued = false
  if queuedGuid then
    schedule()
  end
end

schedule = function()
  local wait = math.max(lastNotify + THROTTLE, queuedAt + HOVER_DELAY) - _G.GetTime()
  if not waiting and wait <= 0 then
    sendQueued()
  elseif not timerQueued then
    timerQueued = true
    _G.C_Timer.After(waiting and THROTTLE or wait, onTimer)
  end
end

local function inCombatSkip()
  return deps.skipInCombat and deps.skipInCombat() and _G.InCombatLockdown()
end

function InspectCache.Request(unit, guid)
  if guid == nil or Secret.Is(guid) or guid == inflightGuid or guid == queuedGuid or InspectCache.Get(guid) then
    return
  end
  if guid == failedGuid then
    return
  end
  failedGuid = nil
  if Secret.Clean(_G.UnitIsUnit(unit, "player")) then
    readUnit(unit, guid, true)
    return
  end
  if inCombatSkip() or not _G.CanInspect(unit) then
    return
  end
  queuedUnit, queuedGuid, queuedAt = unit, guid, _G.GetTime()
  schedule()
end

ns.InspectCache = InspectCache
return InspectCache
