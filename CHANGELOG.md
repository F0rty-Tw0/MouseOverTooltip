# Changelog

Player-friendly release notes for Mouseover Tooltip. This file covers the current 1.x series; older series live in [archive/changelog/](archive/changelog/).

All releases: **1.0.x (current)** · [0.1.x](archive/changelog/0.1.md)

## [Unreleased]

- Fixed: the Mythic+ rating could stay missing for players outside your group when item level, spec and PvP rating were all turned off.

## [1.0.9] - 2026-11-09

- New Combat options: show the default Blizzard tooltip in combat, separately for characters in the world and for unit frames.
- Fixed: hovering a corpse with rare/elite tags on could show a red "??" instead of the mob's level.

## [1.0.8] - 2026-11-08

- New "Rare colored border" option on the Look tab: silver for rare mobs, lilac for rare elites.
- WoW: Forever: the rare border is on for everyone. New installs also start with rare/elite tags and tapped gray-out on, and item level off. Already installed? Change them in the Players and NPCs tabs, or press Defaults.

## [1.0.7] - 2026-11-07

- Hovering a player, party or raid frame no longer adds the "Right click for Frame Settings" hint to the tooltip.

## [1.0.6] - 2026-11-05

- Wider X, Y and Scale sliders on the General options tab, for finer control.

## [1.0.5] - 2026-11-04

- Ready for the WoW: Forever launch.

## [1.0.4] - 2026-10-24

- Fixed: with a cursor offset set, hovering bag items and other Blizzard tooltips threw "attempt to call a nil value" errors over and over.

## [1.0.3] - 2026-10-14

- New Scale slider on the General tab to make tooltips bigger or smaller (50–200%). Item comparison tooltips resize with it.
- Options are now split into tabs (General, Players, NPCs, Look, Combat). Sub-options sit under the option they depend on and gray out while it's off, and every option explains itself when you hover over it.

## [1.0.2] - 2026-10-08

- The addon now shows as "Mouseover Tooltip" in the addon list, settings and minimap button. Your settings are kept.
- New, sharper addon icon in the addon list, minimap button and addon compartment.
- New X and Y offset sliders under "Tooltip follows cursor" to move the tooltip away from the mouse, one pixel per step.
- Fixed: hovering enemy nameplates in dungeons and raids no longer causes a Lua error.
- Fixed: player and target info that the game hides in dungeons and raids is now skipped instead of risking a Lua error.
- Fixed: "Hide health bar", "Hide world units in combat" and "Hide unit frames in combat" now work in Mythic+.

## [1.0.1] - 2026-10-06

- Fixed: player tooltips in WoW: Forever now show the character's surname next to their first name.

## [1.0.0] - 2026-09-27

- Fixed: player tooltips no longer show an empty line that fills in a moment later with item level (Retail).
- Item level shows "iLvl ..." while it loads, so the tooltip no longer jumps when the number arrives. If the player can't be inspected, the placeholder goes away.
