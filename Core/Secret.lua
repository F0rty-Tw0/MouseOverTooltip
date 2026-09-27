local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

-- WoW 12.x hands out "secret" unit values in combat/instances that error when
-- compared, concatenated or used as a key. Classic has no issecretvalue.
local issecretvalue = _G.issecretvalue

local Secret = {}

function Secret.Is(value)
  return issecretvalue ~= nil and issecretvalue(value) == true
end

-- Returns value, or nil when it is a secret, so callers can skip the line.
function Secret.Clean(value)
  if issecretvalue ~= nil and issecretvalue(value) then
    return nil
  end
  return value
end

-- Two-return variant for APIs like UnitName (name, realm).
function Secret.Clean2(first, second)
  if issecretvalue ~= nil and (issecretvalue(first) or issecretvalue(second)) then
    if issecretvalue(first) then
      return nil, nil
    end
    return first, nil
  end
  return first, second
end

ns.Secret = Secret
return Secret
