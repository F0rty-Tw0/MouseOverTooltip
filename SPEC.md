# MouseOverTooltip — Feature Spec

Minimal mouseover unit tooltip. Blizzard `GameTooltip` look, clean lines, no libraries.
Selling point: **lowest CPU, memory and addon size of any tooltip addon.**

## Scope

- Flavors: Retail + all Classic flavors + WoW: Forever (one TOC, `## Interface-*` lines, like WhisperMessenger).
  Retail-only features (M+, spec via inspect on Vanilla, PvP rating, AddOn Compartment) are hidden where the API is missing — gate through `Core/FlavorCompat.lua`.
- Unit tooltips only, plus one item feature (quality-colored border).
- English only. Every player-visible string goes through `Localization.Text("...")` so languages can be added later.

## Performance rules (non-negotiable)

1. **No persistent `OnUpdate` handlers.** Cursor anchoring uses the native `ANCHOR_CURSOR*` anchor, not a per-frame reposition. Only exception: the minimap button follows the ring while being dragged; the handler is removed on drop.
2. **No libraries** (no LibStub, LDB, LibDBIcon, AceDB …).
3. **Events registered only while needed** — e.g. `INSPECT_READY` only while an inspect is pending.
4. **Zero work for disabled features** — a disabled line must not call its APIs.
5. **Session caches are capped** — inspect cache: max 100 GUIDs, 5 min TTL, never persisted.
6. **No tables created per hover in hot paths** where a reused buffer works; build strings with `table.concat`.
7. **Secret values (WoW 12.x):** any unit value may be a secret in combat/instances. Check with `issecretvalue` (when it exists) before comparing, concatenating or using as a table key; skip the line instead of erroring.
8. Release zip is minified by CI (already in the release workflow).

## Tooltip layout

Player:

```
{raid icon} Name - Title <AFK> <Dead> (Friend)   class colored
<Guild> - Rank                                    my-guild highlight color when same guild
Realm                                             only cross-realm
80 Human Frost Mage (Alliance)                    level difficulty-colored, faction colored
iLvl 639 • DPS
M+ 2845 • Best +14                                one line, Blizzard rating color
PvP 2100 (Solo Shuffle)
Mount: {icon} Swift Spectral Tiger                source line if not collected
Target: <<YOU>> / Name
Targeted by: Name1, Name2
```

NPC / mob:

```
{raid icon} Name <Dead>        reaction color, gray when tapped by others
80 Elite Humanoid              classification color-coded
Hostile                        reaction text
Forces: 4 (1.2%)               keystone only, via Mythic Dungeon Tools if loaded
Boar Hunt                      quest title
  6/10 Boar slain (4 left)     done objectives in green
Owner: Playername              pets / companions
```

## Settings

Default WoW options: **Options → AddOns → MouseOverTooltip** (Settings API; `InterfaceOptions_AddCategory` fallback only if a flavor lacks it).
The panel's native **Defaults** button is the "reset to defaults" button. Extra: `/mot` opens the panel.

Account-wide SavedVariables: `MouseOverTooltipDB`.

| Setting | Default |
| --- | --- |
| **Player lines** | |
| Name, guild + rank, level, race, class, faction | on |
| Item level (inspect) | on |
| M+ rating + best key | on |
| Mount (+ collected state) | on |
| Mount icon | off |
| Mount source when not collected | off |
| Show mount only when not collected | off |
| Spec + role (inspect) | off |
| Realm + AFK/DND/Offline status | off |
| Player title | off |
| My-guild highlight | off |
| Friend / Battle.net tag | off |
| PvP rating (inspect, retail) | off |
| Target line | off |
| Targeted by group | off |
| **NPC lines** | |
| Quest progress (title + `x/y (n left)`) | on |
| Classification (Rare/Elite/Boss) | off |
| M+ enemy forces (needs MDT) | off |
| Tapped gray-out | off |
| Reaction text | off |
| Pet owner line | off |
| **Visuals** | |
| Tooltip follows cursor | on |
| Health text on bar | off |
| Hide health bar | off |
| Raid marker icon | off |
| Dead / Ghost tag | off |
| Class/reaction colored border | off |
| Item quality colored border | off |
| **Combat** | |
| Hide world-unit tooltips in combat | off |
| Hide unit-frame tooltips in combat | off |
| Hold Shift to show hidden tooltips | on (only matters when a hide is on) |
| Skip inspect in combat | on |
| **Misc** | |
| Minimap button (native, draggable) | on |

Retail also gets an AddOn Compartment entry (TOC fields, zero runtime cost).

## Out of scope (decided)

- Item/spell ID lines, item level on item tooltips, restyled frames, fonts, profiles, localization catalogs, per-character settings, persisted inspect cache.
