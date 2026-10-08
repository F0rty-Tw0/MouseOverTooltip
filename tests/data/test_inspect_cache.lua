local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")

local W

local function setup(options)
  W = Wow.Install()
  _G.C_PaperDollInfo = {
    GetInspectItemLevel = function(unit)
      return W.units[unit] and W.units[unit].ilvl
    end,
  }
  _G.GetInspectSpecialization = function(unit)
    return W.units[unit] and W.units[unit].specID or 0
  end
  _G.GetSpecializationInfoByID = function() end
  package.loaded["Core.FlavorCompat"] = nil
  package.loaded["Data.InspectCache"] = nil
  local InspectCache = require("MouseOverTooltip.Data.InspectCache")
  options = options or {}
  local ready = {}
  InspectCache.Configure({
    skipInCombat = function()
      return options.skipInCombat ~= false
    end,
    onReady = function(guid)
      table.insert(ready, guid)
    end,
    wantsPvp = function()
      return options.wantsPvp == true
    end,
    readPvp = options.readPvp,
  })
  W.units.mouseover = { name = "Bob", guid = "Player-1", isPlayer = true, ilvl = 639, specID = 64 }
  return InspectCache, ready
end

local function inspectFrame()
  for _, frame in ipairs(W.frames) do
    if frame.scripts.OnEvent then
      return frame
    end
  end
end

-- Hover, then let the hover-pause timer fire so the inspect goes out.
local function hoverAndWait(InspectCache, unit, guid)
  InspectCache.Request(unit, guid)
  W.RunTimers()
end

local function test_request_inspects_and_caches_on_ready()
  local InspectCache, ready = setup()
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  Assert.equal(W.lastInspect, "mouseover")
  local frame = inspectFrame()
  Assert.equal(frame.events.INSPECT_READY, true, "registered while pending")
  frame:FireEvent("INSPECT_READY", "Player-1")
  Assert.equal(frame.events.INSPECT_READY, nil, "unregistered after data")
  Assert.equal(W.calls.ClearInspectPlayer, 1)
  local entry = InspectCache.Get("Player-1")
  Assert.equal(entry.ilvl, 639)
  Assert.equal(entry.specID, 64)
  Assert.equal(ready[1], "Player-1")
end

local function test_event_not_registered_until_first_request()
  setup()
  Assert.equal(inspectFrame(), nil)
end

local function test_fresh_cache_skips_notify_inspect()
  local InspectCache = setup()
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  inspectFrame():FireEvent("INSPECT_READY", "Player-1")
  W.now = W.now + 10
  InspectCache.Request("mouseover", "Player-1")
  Assert.equal(W.calls.NotifyInspect, 1)
end

local function test_expired_entry_is_reinspected()
  local InspectCache = setup()
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  inspectFrame():FireEvent("INSPECT_READY", "Player-1")
  W.now = W.now + 301
  Assert.equal(InspectCache.Get("Player-1"), nil)
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  Assert.equal(W.calls.NotifyInspect, 2)
end

local function test_requests_inside_throttle_are_queued_on_a_timer()
  local InspectCache = setup()
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  inspectFrame():FireEvent("INSPECT_READY", "Player-1")
  W.units.mouseover = { name = "Amy", guid = "Player-2", isPlayer = true, ilvl = 600 }
  W.now = W.now + 0.5
  InspectCache.Request("mouseover", "Player-2")
  Assert.equal(W.calls.NotifyInspect, 1, "throttled")
  W.RunTimers()
  Assert.equal(W.calls.NotifyInspect, 2, "sent when throttle passes")
end

local function test_queued_request_dropped_when_unit_changed()
  local InspectCache = setup()
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  inspectFrame():FireEvent("INSPECT_READY", "Player-1")
  W.units.mouseover = { name = "Amy", guid = "Player-2", isPlayer = true }
  InspectCache.Request("mouseover", "Player-2")
  W.units.mouseover = nil
  W.RunTimers()
  Assert.equal(W.calls.NotifyInspect, 1)
end

local function test_combat_skip_follows_setting()
  local InspectCache = setup()
  W.inCombat = true
  InspectCache.Request("mouseover", "Player-1")
  Assert.equal(W.calls.NotifyInspect, nil, "skipped in combat")

  InspectCache = setup({ skipInCombat = false })
  W.inCombat = true
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  Assert.equal(W.calls.NotifyInspect, 1, "setting off inspects in combat")
end

local function test_timeout_unregisters_event()
  local InspectCache = setup()
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  W.now = W.now + 5
  W.RunTimers()
  Assert.equal(inspectFrame().events.INSPECT_READY, nil)
end

local function test_pending_from_hover_until_data_arrives()
  local InspectCache = setup()
  InspectCache.Request("mouseover", "Player-1")
  Assert.equal(InspectCache.IsPending("Player-1"), true, "queued")
  W.RunTimers()
  Assert.equal(InspectCache.IsPending("Player-1"), true, "in flight")
  inspectFrame():FireEvent("INSPECT_READY", "Player-1")
  Assert.equal(InspectCache.IsPending("Player-1"), false)
end

local function test_timeout_refreshes_and_does_not_retry_same_player()
  local InspectCache, ready = setup()
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  W.now = W.now + 5
  W.RunTimers()
  Assert.equal(ready[1], "Player-1", "tooltip rebuilt without the placeholder")
  InspectCache.Request("mouseover", "Player-1")
  Assert.equal(InspectCache.IsPending("Player-1"), false, "no retry loop while hovering")
end

local function test_hovering_another_player_allows_retry_after_timeout()
  local InspectCache = setup()
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  W.now = W.now + 5
  W.RunTimers()
  W.units.target = { name = "Amy", guid = "Player-2", isPlayer = true }
  InspectCache.Request("target", "Player-2")
  InspectCache.Request("mouseover", "Player-1")
  Assert.equal(InspectCache.IsPending("Player-1"), true)
end

local function test_dropped_request_refreshes_tooltip()
  local InspectCache, ready = setup()
  InspectCache.Request("mouseover", "Player-1")
  W.units.mouseover.isPlayer = false
  W.RunTimers()
  Assert.equal(W.calls.NotifyInspect, nil)
  Assert.equal(ready[1], "Player-1")
end

local function test_other_inspects_are_ignored()
  local InspectCache = setup()
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  inspectFrame():FireEvent("INSPECT_READY", "Player-9")
  Assert.equal(InspectCache.Get("Player-9"), nil)
  Assert.equal(inspectFrame().events.INSPECT_READY, true, "still waiting for ours")
end

local function test_cache_is_capped_at_100_evicting_oldest()
  local InspectCache = setup()
  for i = 1, 101 do
    local guid = "Player-c" .. i
    W.units.mouseover = { name = "P" .. i, guid = guid, isPlayer = true, ilvl = i }
    W.now = W.now + 2
    hoverAndWait(InspectCache, "mouseover", guid)
    inspectFrame():FireEvent("INSPECT_READY", guid)
  end
  Assert.equal(InspectCache.Count(), 100)
  Assert.equal(InspectCache.Get("Player-c1"), nil, "oldest evicted")
  Assert.equal(InspectCache.Get("Player-c101").ilvl, 101)
end

local function test_pvp_read_with_inspect_data_when_wanted()
  local pvpCalls = 0
  local InspectCache = setup({
    wantsPvp = true,
    readPvp = function()
      pvpCalls = pvpCalls + 1
      return 2100, "Solo Shuffle"
    end,
  })
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  inspectFrame():FireEvent("INSPECT_READY", "Player-1")
  Assert.equal(pvpCalls, 1)
  Assert.equal(InspectCache.Get("Player-1").pvpRating, 2100)
  Assert.equal(InspectCache.Get("Player-1").pvpBracket, "Solo Shuffle")
  Assert.equal(inspectFrame().events.INSPECT_READY, nil)
end

local function test_pvp_off_never_reads_pvp()
  local pvpCalls = 0
  local InspectCache = setup({
    wantsPvp = false,
    readPvp = function()
      pvpCalls = pvpCalls + 1
    end,
  })
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  inspectFrame():FireEvent("INSPECT_READY", "Player-1")
  Assert.equal(pvpCalls, 0)
end

local function test_namespaced_inspect_specialization_preferred()
  local InspectCache = setup()
  _G.C_SpecializationInfo = {
    GetInspectSpecialization = function()
      return 250
    end,
  }
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  inspectFrame():FireEvent("INSPECT_READY", "Player-1")
  Assert.equal(InspectCache.Get("Player-1").specID, 250)
  _G.C_SpecializationInfo = nil
end

local function test_inspect_waits_for_hover_pause()
  local InspectCache = setup()
  InspectCache.Request("mouseover", "Player-1")
  Assert.equal(W.calls.NotifyInspect, nil, "not sent while the cursor may still be moving")
  W.RunTimers()
  Assert.equal(W.calls.NotifyInspect, 1)
end

local function test_sweeping_past_player_never_inspects()
  local InspectCache = setup()
  InspectCache.Request("mouseover", "Player-1")
  W.units.mouseover = nil
  W.RunTimers()
  Assert.equal(W.calls.NotifyInspect, nil)
end

local function test_repeat_hover_does_not_restart_pause()
  local InspectCache = setup()
  local start = W.now
  InspectCache.Request("mouseover", "Player-1")
  W.now = start + 0.25
  InspectCache.Request("mouseover", "Player-1")
  local timer = table.remove(W.timers, 1)
  W.now = start + 0.3
  timer.fn()
  Assert.equal(W.calls.NotifyInspect, 1, "tooltip refreshes keep the first hover time")
end

local function test_secret_guid_is_never_requested()
  setup()
  local marker = {}
  rawset(_G, "issecretvalue", function(v)
    return v == marker
  end)
  package.loaded["Core.Secret"] = nil
  package.loaded["Data.InspectCache"] = nil
  local InspectCache = require("MouseOverTooltip.Data.InspectCache")
  InspectCache.Configure({})
  InspectCache.Request("mouseover", marker)
  Assert.equal(W.calls.NotifyInspect, nil)
  rawset(_G, "issecretvalue", nil)
  package.loaded["Core.Secret"] = nil
end

-- A secret "is this me" answer must not be read as yes: inspect as usual.
local function test_secret_self_check_still_inspects()
  setup()
  local marker = {}
  rawset(_G, "issecretvalue", function(v)
    return v == marker
  end)
  rawset(_G, "UnitIsUnit", function()
    return marker
  end)
  package.loaded["Core.Secret"] = nil
  package.loaded["Data.InspectCache"] = nil
  local InspectCache = require("MouseOverTooltip.Data.InspectCache")
  InspectCache.Configure({})
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  Assert.equal(W.calls.NotifyInspect, 1)
  rawset(_G, "issecretvalue", nil)
  package.loaded["Core.Secret"] = nil
end

-- The GUID is already known clean, so hovering yourself needs no inspect even
-- when the "is this me" answer is secret.
local function test_secret_self_check_reads_self_by_guid()
  setup()
  W.units.player = W.units.mouseover
  local marker = {}
  rawset(_G, "issecretvalue", function(v)
    return v == marker
  end)
  rawset(_G, "UnitIsUnit", function()
    return marker
  end)
  package.loaded["Core.Secret"] = nil
  package.loaded["Data.InspectCache"] = nil
  local InspectCache = require("MouseOverTooltip.Data.InspectCache")
  InspectCache.Configure({})
  hoverAndWait(InspectCache, "mouseover", "Player-1")
  Assert.equal(W.calls.NotifyInspect, nil)
  rawset(_G, "issecretvalue", nil)
  package.loaded["Core.Secret"] = nil
end

return function()
  test_event_not_registered_until_first_request()
  test_request_inspects_and_caches_on_ready()
  test_fresh_cache_skips_notify_inspect()
  test_expired_entry_is_reinspected()
  test_requests_inside_throttle_are_queued_on_a_timer()
  test_queued_request_dropped_when_unit_changed()
  test_combat_skip_follows_setting()
  test_timeout_unregisters_event()
  test_pending_from_hover_until_data_arrives()
  test_timeout_refreshes_and_does_not_retry_same_player()
  test_hovering_another_player_allows_retry_after_timeout()
  test_dropped_request_refreshes_tooltip()
  test_other_inspects_are_ignored()
  test_cache_is_capped_at_100_evicting_oldest()
  test_pvp_read_with_inspect_data_when_wanted()
  test_pvp_off_never_reads_pvp()
  test_namespaced_inspect_specialization_preferred()
  test_inspect_waits_for_hover_pause()
  test_sweeping_past_player_never_inspects()
  test_repeat_hover_does_not_restart_pause()
  test_secret_guid_is_never_requested()
  test_secret_self_check_still_inspects()
  test_secret_self_check_reads_self_by_guid()
end
