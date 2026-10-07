local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

-- One ordered list drives SavedVariables defaults and the options panel.
-- `requires` names a FlavorCompat flag; the panel hides the row without it.
-- `{ column = 2 }` starts the panel's right column.
-- `min`/`max` make a numeric slider setting; `sameRow` puts it beside the
-- previous slider.
local OFFSET_HINT = "Moves the tooltip away from the cursor, in pixels. Needs 'Tooltip follows cursor'."
local OFFSET_LIMIT = 100

local Defaults = {
  list = {
    { header = "Player header" },
    { key = "colorName", default = true, label = "Class-colored name" },
    { key = "showGuild", default = true, label = "Guild + rank" },
    { key = "showLevel", default = true, label = "Level" },
    { key = "showRace", default = true, label = "Race" },
    { key = "showClass", default = true, label = "Class" },
    { key = "showFaction", default = true, label = "Faction" },

    { header = "Player info" },
    { key = "showItemLevel", default = true, label = "Item level (inspect)", requires = "hasItemLevel" },
    { key = "showMythicPlus", default = true, label = "M+ rating + best key", requires = "hasMythicPlus" },
    { key = "showSpec", default = false, label = "Spec + role (inspect)", requires = "hasSpec" },
    { key = "showPvpRating", default = false, label = "PvP rating (inspect)", requires = "hasPvpRating" },
    { key = "showRealmStatus", default = false, label = "Realm + AFK/DND status" },
    { key = "showTitle", default = false, label = "Player title" },
    { key = "highlightMyGuild", default = false, label = "My-guild highlight" },
    { key = "showFriend", default = false, label = "Friend / Battle.net tag" },
    { key = "showTarget", default = false, label = "Target line" },
    { key = "showTargetedBy", default = false, label = "Targeted by group" },

    { header = "Mount" },
    { key = "showMount", default = true, label = "Mount + collected state", requires = "hasMountJournal" },
    { key = "showMountIcon", default = false, label = "Icon", requires = "hasMountJournal" },
    { key = "showMountSource", default = false, label = "Source when not collected", requires = "hasMountJournal" },
    { key = "mountOnlyUncollected", default = false, label = "Only when not collected", requires = "hasMountJournal" },

    { column = 2 },

    { header = "NPC lines" },
    { key = "showQuest", default = true, label = "Quest progress" },
    { key = "showClassification", default = false, label = "Classification (Rare/Elite/Boss)" },
    { key = "showEnemyForces", default = false, label = "M+ enemy forces (needs MDT)", requires = "hasMythicPlus" },
    { key = "grayTapped", default = false, label = "Tapped gray-out" },
    { key = "showReaction", default = false, label = "Reaction text" },
    { key = "showPetOwner", default = false, label = "Pet owner line" },

    { header = "Visuals" },
    { key = "followCursor", default = true, label = "Tooltip follows cursor" },
    { key = "cursorOffsetX", default = 0, min = -OFFSET_LIMIT, max = OFFSET_LIMIT, label = "X", hint = OFFSET_HINT },
    {
      key = "cursorOffsetY",
      default = 0,
      min = -OFFSET_LIMIT,
      max = OFFSET_LIMIT,
      label = "Y",
      hint = OFFSET_HINT,
      sameRow = true,
    },
    { key = "healthText", default = false, label = "Health text on bar" },
    { key = "hideHealthBar", default = false, label = "Hide health bar" },
    { key = "showRaidIcon", default = false, label = "Raid marker icon" },
    { key = "showDeadTag", default = false, label = "Dead / Ghost tag" },
    { key = "classBorder", default = false, label = "Class/reaction colored border" },
    { key = "itemQualityBorder", default = false, label = "Item quality colored border" },

    { header = "Combat" },
    { key = "hideWorldInCombat", default = false, label = "Hide world units in combat" },
    { key = "hideFramesInCombat", default = false, label = "Hide unit frames in combat" },
    { key = "shiftShowsHidden", default = true, label = "Shift shows hidden tooltips" },
    { key = "skipInspectInCombat", default = true, label = "Skip inspect in combat" },

    { header = "Misc" },
    { key = "minimapButton", default = true, label = "Minimap button" },
  },

  -- Non-setting state kept in the same SavedVariables table.
  state = {
    minimapAngle = 225,
  },
}

ns.SettingsDefaults = Defaults
return Defaults
