local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

-- One ordered list drives SavedVariables defaults and the options panel.
-- `{ tab = "Name" }` starts a panel tab; its value is both the tab's identity
-- and its English button text. Every entry after it belongs to that tab.
-- `{ column = 2 }` starts the tab's right column.
-- `{ header = "..." }` adds a group header.
-- `requires` names a FlavorCompat flag; the panel hides the row without it.
-- `parent` names an earlier checkbox key in the same tab; the row is its child.
-- `hint` is the one-sentence hover help every setting row carries.
-- `min`/`max` make a numeric slider setting; `sameRow` puts it beside the
-- previous slider; `labelWidth` widens its label column; `suffix` follows
-- the shown value.
local OFFSET_HINT = "Moves the tooltip away from the cursor, in pixels. Needs 'Tooltip follows cursor'."
local OFFSET_LIMIT = 100
local SCALE_HINT = "Size of the tooltip, in percent of normal."
local INSPECT_NOTE = "; needs an inspect, so it appears a moment later."
local MOUNT = "hasMountJournal"

local Defaults = {
  list = {
    { tab = "General" },
    { header = "Cursor" },
    {
      key = "followCursor",
      default = true,
      label = "Tooltip follows cursor",
      hint = "Shows the tooltip at your mouse cursor instead of the screen corner.",
    },
    {
      key = "cursorOffsetX",
      default = 0,
      min = -OFFSET_LIMIT,
      max = OFFSET_LIMIT,
      label = "X",
      hint = OFFSET_HINT,
      parent = "followCursor",
    },
    {
      key = "cursorOffsetY",
      default = 0,
      min = -OFFSET_LIMIT,
      max = OFFSET_LIMIT,
      label = "Y",
      hint = OFFSET_HINT,
      parent = "followCursor",
      sameRow = true,
    },
    {
      key = "tooltipScale",
      default = 100,
      min = 50,
      max = 200,
      label = "Scale",
      hint = SCALE_HINT,
      labelWidth = 40,
      suffix = "%",
    },
    { header = "Misc" },
    {
      key = "minimapButton",
      default = true,
      label = "Minimap button",
      hint = "Shows a minimap button you can drag around; click it to open these options.",
    },

    { tab = "Players" },
    { header = "Player header" },
    { key = "colorName", default = true, label = "Class-colored name", hint = "Colors player names in their class color." },
    { key = "showGuild", default = true, label = "Guild + rank", hint = "Shows the player's guild and their rank in it." },
    {
      key = "showLevel",
      default = true,
      label = "Level",
      hint = "Shows the player's level, colored by how tough they are for you.",
    },
    { key = "showRace", default = true, label = "Race", hint = "Shows the player's race." },
    { key = "showClass", default = true, label = "Class", hint = "Shows the player's class." },
    { key = "showFaction", default = true, label = "Faction", hint = "Shows whether the player is Alliance or Horde." },
    { header = "Mount" },
    {
      key = "showMount",
      default = true,
      label = "Mount + collected state",
      hint = "Shows the mount the player is riding and whether you have it too.",
      requires = MOUNT,
    },
    {
      key = "showMountIcon",
      default = false,
      label = "Icon",
      hint = "Adds the mount's icon in front of its name.",
      requires = MOUNT,
      parent = "showMount",
    },
    {
      key = "showMountSource",
      default = false,
      label = "Source when not collected",
      hint = "Shows where to get a mount you don't have yet.",
      requires = MOUNT,
      parent = "showMount",
    },
    {
      key = "mountOnlyUncollected",
      default = false,
      label = "Only when not collected",
      hint = "Hides the mount line for mounts you already own.",
      requires = MOUNT,
      parent = "showMount",
    },

    { column = 2 },

    { header = "Player info" },
    {
      key = "showItemLevel",
      default = true,
      label = "Item level (inspect)",
      hint = "Shows the player's item level" .. INSPECT_NOTE,
      requires = "hasItemLevel",
    },
    {
      key = "showMythicPlus",
      default = true,
      label = "M+ rating + best key",
      hint = "Shows the player's Mythic+ rating and best timed key level this season.",
      requires = "hasMythicPlus",
    },
    {
      key = "showSpec",
      default = false,
      label = "Spec + role (inspect)",
      hint = "Shows the player's spec and role" .. INSPECT_NOTE,
      requires = "hasSpec",
    },
    {
      key = "showPvpRating",
      default = false,
      label = "PvP rating (inspect)",
      hint = "Shows the player's PvP rating and bracket" .. INSPECT_NOTE,
      requires = "hasPvpRating",
    },
    {
      key = "showRealmStatus",
      default = false,
      label = "Realm + AFK/DND status",
      hint = "Shows the realm of players from other realms, and AFK, DND or Offline status.",
    },
    { key = "showTitle", default = false, label = "Player title", hint = "Shows the player's chosen title next to their name." },
    {
      key = "highlightMyGuild",
      default = false,
      label = "My-guild highlight",
      hint = "Colors the guild line differently when the player is in your guild.",
    },
    {
      key = "showFriend",
      default = false,
      label = "Friend / Battle.net tag",
      hint = "Marks players who are on your friends or Battle.net friends list.",
    },
    {
      key = "showTarget",
      default = false,
      label = "Target line",
      hint = "Shows who the player is targeting, or <<YOU>> when it's you.",
    },
    {
      key = "showTargetedBy",
      default = false,
      label = "Targeted by group",
      hint = "Lists the members of your party or raid who are targeting the player.",
    },

    { tab = "NPCs" },
    { header = "NPC lines" },
    {
      key = "showQuest",
      default = true,
      label = "Quest progress",
      hint = "Adds how many are left to quest objectives, like 6/10 (4 left), and colors finished ones.",
    },
    {
      key = "showClassification",
      default = false,
      label = "Classification (Rare/Elite/Boss)",
      hint = "Shows Rare, Elite or Boss on the level line, color-coded.",
    },
    {
      key = "showEnemyForces",
      default = false,
      label = "M+ enemy forces (needs MDT)",
      hint = "Shows how much a mob adds to Mythic+ enemy forces; needs the Mythic Dungeon Tools addon.",
      requires = "hasMythicPlus",
    },
    {
      key = "grayTapped",
      default = false,
      label = "Tapped gray-out",
      hint = "Grays the name of mobs another player tagged first; they give you no loot.",
    },
    {
      key = "showReaction",
      default = false,
      label = "Reaction text",
      hint = "Shows whether the NPC is Hostile, Neutral or Friendly to you.",
    },
    {
      key = "showPetOwner",
      default = false,
      label = "Pet owner line",
      hint = 'Rewrites the "Name\'s Pet" line on pets and companions as "Owner: Name".',
    },

    { tab = "Look" },
    { header = "Health bar" },
    {
      key = "healthText",
      default = false,
      label = "Health text on bar",
      hint = "Shows current and maximum health as numbers on the health bar.",
    },
    { key = "hideHealthBar", default = false, label = "Hide health bar", hint = "Removes the health bar under the tooltip." },
    { header = "Markers" },
    {
      key = "showRaidIcon",
      default = false,
      label = "Raid marker icon",
      hint = "Shows the unit's raid marker, like skull or star, before its name.",
    },
    {
      key = "showDeadTag",
      default = false,
      label = "Dead / Ghost tag",
      hint = "Adds a Dead or Ghost tag after the names of dead units.",
    },
    { header = "Borders" },
    {
      key = "classBorder",
      default = false,
      label = "Class/reaction colored border",
      hint = "Colors the border by class for players, or by friend or foe for NPCs.",
    },
    {
      key = "itemQualityBorder",
      default = false,
      label = "Item quality colored border",
      hint = "Colors item tooltip borders by quality, like purple for epic items.",
    },

    { tab = "Combat" },
    { header = "Combat" },
    {
      key = "hideWorldInCombat",
      default = false,
      label = "Hide world units in combat",
      hint = "Hides tooltips for characters in the game world while you're in combat.",
    },
    {
      key = "hideFramesInCombat",
      default = false,
      label = "Hide unit frames in combat",
      hint = "Hides tooltips for unit frames, like party frames, while you're in combat.",
    },
    {
      key = "shiftShowsHidden",
      default = true,
      label = "Shift shows hidden tooltips",
      hint = "Hold Shift to see a tooltip that a combat setting above would hide.",
    },
    {
      key = "skipInspectInCombat",
      default = true,
      label = "Skip inspect in combat",
      hint = "Skips player inspects in combat; item level, spec and PvP load on your next hover after.",
    },
  },

  -- Non-setting state kept in the same SavedVariables table.
  state = {
    minimapAngle = 225,
  },
}

ns.SettingsDefaults = Defaults
return Defaults
