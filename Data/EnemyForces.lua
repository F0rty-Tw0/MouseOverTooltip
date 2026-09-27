local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Localization = ns.Localization or require("MouseOverTooltip.Core.Localization")

local format = string.format
local match = string.match
local pairs = pairs
local tonumber = tonumber

local EnemyForces = {}

-- Lookups into Mythic Dungeon Tools' tables, filled on first use per key.
local dungeonByMap = {}
local enemyByNpc = {}

local function dungeonIndex(mdt, mapId)
  local index = dungeonByMap[mapId]
  if index == nil and type(mdt.mapInfo) == "table" then
    for candidate, info in pairs(mdt.mapInfo) do
      if type(info) == "table" and info.mapID == mapId then
        index = candidate
        break
      end
    end
    dungeonByMap[mapId] = index or false
  end
  return index or nil
end

local function findEnemy(enemies, dungeon, npcId)
  local byNpc = enemyByNpc[dungeon]
  if not byNpc then
    byNpc = {}
    for _, enemy in pairs(enemies) do
      if type(enemy) == "table" and enemy.id then
        byNpc[enemy.id] = enemy
      end
    end
    enemyByNpc[dungeon] = byNpc
  end
  return byNpc[npcId]
end

-- "Forces: 4 (1.3%)" inside an active keystone when MDT is loaded.
function EnemyForces.Line(guid)
  local mdt = _G.MDT
  local mapId = mdt and _G.C_ChallengeMode.GetActiveChallengeMapID()
  if not mapId or type(mdt.dungeonEnemies) ~= "table" then
    return nil
  end
  local dungeon = dungeonIndex(mdt, mapId)
  local enemies = dungeon and mdt.dungeonEnemies[dungeon]
  local npcId = tonumber(match(guid, "%-(%d+)%-%x+$"))
  local enemy = enemies and npcId and findEnemy(enemies, dungeon, npcId)
  local count = enemy and enemy.count
  if not count or count <= 0 then
    return nil
  end
  local totals = type(mdt.dungeonTotalCount) == "table" and mdt.dungeonTotalCount[dungeon]
  local total = totals and totals.normal
  if total and total > 0 then
    return format("%s: %d (%.1f%%)", Localization.Text("Forces"), count, count / total * 100)
  end
  return format("%s: %d", Localization.Text("Forces"), count)
end

ns.EnemyForces = EnemyForces
return EnemyForces
