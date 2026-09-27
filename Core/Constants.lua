local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Constants = {
  VERSION = "v0.1.0",

  -- Inspect cache: session-only, never persisted.
  INSPECT_CACHE_MAX = 100,
  INSPECT_CACHE_TTL = 300,
  -- Seconds between NotifyInspect calls; the server drops faster requests.
  INSPECT_THROTTLE = 1.5,
  -- Seconds the cursor must rest on a player before inspecting, so sweeping
  -- across a crowd sends nothing.
  INSPECT_HOVER_DELAY = 0.3,
  -- Seconds to wait for INSPECT_READY before giving up on a request.
  INSPECT_TIMEOUT = 3,
}

ns.Constants = Constants
return Constants
