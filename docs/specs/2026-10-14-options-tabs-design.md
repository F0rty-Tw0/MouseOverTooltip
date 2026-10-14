# Options panel: tabs, nested options, hover help

Date: 2026-10-14. Status: approved design, awaiting plan.

## Goal

The options page (Options → AddOns → Mouseover Tooltip) is one two-column wall of ~40 rows under 7 headers. Replace it with five tabs inside the same panel, show which options depend on another, and explain each option on hover. Players should find a setting by task, not by scanning.

## Non-goals

- No new, removed or renamed settings. Every `key`, `default`, `min`, `max` in `Settings/Defaults.lua` stays as it is, so saved settings (`MouseOverTooltipDB`) carry over untouched.
- No Blizzard sidebar subcategories, no scroll frames, no libraries, no custom art.
- No persisted "last tab" — session only.

## User-visible behavior

1. Under the panel title, a row of five tab buttons: **General · Players · NPCs · Look · Combat**. One tab's options show at a time. Clicking a tab shows its options and hides the previous tab's.
2. The panel opens on **General** the first time per session; afterwards it reopens on the last tab clicked this session.
3. The selected tab's button looks selected (highlight locked on); the others look normal.
4. Tab contents (top to bottom, each group under a small header as today):

   | Tab | Groups and rows (existing labels) |
   | --- | --- |
   | General | **Cursor**: Tooltip follows cursor; X and Y (same row, indented, children of follows cursor); Scale. **Misc**: Minimap button |
   | Players | Left column — **Player header**: Class-colored name, Guild + rank, Level, Race, Class, Faction; **Mount**: Mount + collected state; Icon, Source when not collected, Only when not collected (indented, children of Mount + collected state). Right column — **Player info**: Item level (inspect), M+ rating + best key, Spec + role (inspect), PvP rating (inspect), Realm + AFK/DND status, Player title, My-guild highlight, Friend / Battle.net tag, Target line, Targeted by group |
   | NPCs | **NPC lines**: Quest progress, Classification (Rare/Elite/Boss), M+ enemy forces (needs MDT), Tapped gray-out, Reaction text, Pet owner line |
   | Look | **Health bar**: Health text on bar, Hide health bar. **Markers**: Raid marker icon, Dead / Ghost tag. **Borders**: Class/reaction colored border, Item quality colored border |
   | Combat | **Combat**: Hide world units in combat, Hide unit frames in combat, Shift shows hidden tooltips, Skip inspect in combat |

   The table places every setting row of `Defaults.list` (41 keys). A setting missing from it during implementation means stop and ask.

5. **Child options** (rows with a `parent`) are indented one step to the right of their parent. While the parent's saved value is `false`, every child is disabled: a checkbox can't be clicked; a slider's track and both stepper buttons can't change the value (the template frame's `SetEnabled(false)`); and the row's label FontString switches from `GameFontHighlight` to `GameFontDisable` (back on enable). The slider's value text is part of the template and follows the template's own disabled look. The child's saved value is not changed. Turning the parent back on re-enables the children immediately.
   Only one level: a parent is always a checkbox (no `min`) and is never itself a child.
6. **Hover help**: hovering any checkbox or slider shows GameTooltip with that option's one-sentence hint; leaving hides it. Disabled children still show their hint. Every setting row has a hint. Hints are plain English, describe the in-game effect, at most ~90 characters, and go through `Localization.Text`. Tab labels and group headers (including the new Cursor, Health bar, Markers, Borders) go through `Localization.Text` too.
7. The Blizzard **Defaults** button resets every setting on every tab (built or not), forwards each change as today, and refreshes the built widgets, including the disabled state of children.
8. Rows whose `requires` flag is missing on the current flavor stay hidden, as today. A child's `requires` equals its parent's, so a hidden parent never leaves orphan children.

## Performance (SPEC rules)

- At login only the empty canvas frame exists (unchanged).
- First panel open builds the tab buttons and only the selected tab's widgets. Each other tab builds its widgets the first time it is selected, never again.
- No `OnUpdate`, no events registered, no timers. Enable/disable runs only on a tab's first build, a parent's click, refresh and Defaults.

## Data model (`Settings/Defaults.lua`)

`Defaults.list` stays one ordered list; SavedState keeps reading only entries with `key`.

- `{ tab = "General" }` starts a tab. The `tab` value is both the tab's identity and its English button text (shown through `Localization.Text`). Every entry after it belongs to that tab until the next `tab` marker. The first list entry is a tab marker.
- `{ column = 2 }` starts the right column of the current tab (used only in Players).
- `{ header = "..." }` unchanged.
- New optional field `parent = "<key>"`: the row is a child of the setting with that key. Parent and child are in the same tab, parent listed first.
- New field `hint = "..."` on every setting row (sliders already have it).
- Existing fields `requires`, `min`, `max`, `sameRow`, `labelWidth`, `suffix` keep their meaning.

## Code layout

- `Settings/Widgets.lua` (new): builders moved out of `Panel.lua` — text label, checkbox, slider, hover hint — plus `Widgets.SetEnabled(widget, enabled)` for gray-out. Builders return the checkbox / slider template frame itself with its label FontString at `frame.label`, as today (no wrapper object): `tests/test_bootstrap.lua` and the `boxes()` helper in `test_panel.lua` find widgets that way. `SetEnabled` nil-checks the methods it calls (`SetEnabled`, `SetFontObject`). Disabled Buttons don't fire OnEnter/OnLeave by default, so the checkbox builder calls `SetMotionScriptsWhileDisabled(true)` once at build (nil-checked). That is a Button-only API, so sliders don't get it; Blizzard's own slider OnEnter checks `IsEnabled()`, which suggests OnEnter still fires on a disabled slider, but that is unverified: the plan includes an in-game check (hover a disabled X slider on Retail and one Classic client); if no hint appears, hook the hint on a mouse-enabled frame that stays enabled (e.g. the row label area) instead. Module pattern per AGENTS.md (`ns.SettingsWidgets`); depends only on Core modules. Added to `MouseOverTooltip.toc` after `Settings/SavedState.lua` and before `Settings/Panel.lua`.
- `Settings/Panel.lua`: registration, tab row, per-tab lazy build, refresh, Defaults, `Panel.Open` (unchanged API: `Panel.Register(db, onChanged)`, `Panel.Open()`).
- Tab buttons use `UIPanelButtonTemplate` (exists on every supported flavor). Selected tab: `LockHighlight()`; others `UnlockHighlight()`. Nil-check these methods (test stubs).
- Each tab owns one child frame of the canvas; switching tabs hides the old child frame and shows the new one.
- Both files stay under ~300 lines; functions under ~40 lines.

## Tests

`tests/settings/test_panel.lua` (update) and new `tests/settings/test_widgets.lua`. `tests/test_bootstrap.lua` (finds the Scale slider after the first `OnShow`) must stay green unchanged.

Stubs in `tests/helpers/wow.lua`: `Show`/`Hide`/`IsShown`/`SetShown` and `SetTextColor` already exist. Add recording `Enable`/`Disable`/`SetEnabled`/`IsEnabled`, `SetMotionScriptsWhileDisabled` and `LockHighlight`/`UnlockHighlight`; make `SetFontObject` record its font so the gray-label test can assert it.

`test_panel.lua` defines `_G.C_MountJournal = { GetMountFromSpell = function() end }` before requiring the Panel module, so the Mount rows exist for the child tests; the missing-API checks keep using M+ and Item level. Tests find tab buttons by text plus a `scripts.OnClick` handler, because the "Combat" tab button and the "Combat" header share their text.

Behaviors to cover, one test each:

- Only the canvas exists before first open (kept).
- First open builds the General tab's rows only; Players rows don't exist yet.
- Clicking the Players tab builds its rows once; clicking it again builds nothing new.
- Clicking a tab shows its frame and hides the previous tab's frame; the clicked tab's highlight is locked, the previous one's unlocked.
- Reopening the panel (`OnShow` again) keeps the last selected tab.
- Mount children start disabled when `showMount` is false and enabled when true; clicking `showMount` toggles them; their saved values don't change.
- X/Y sliders disable when `followCursor` is off.
- Child rows are indented relative to their parent (x greater than parent's x).
- Checkbox hover shows its hint; leave hides it. Slider hint test kept.
- Every setting entry in `Defaults.list` has a non-empty `hint` and sits after a `tab` marker; every `parent` names a checkbox key (no `min`) listed earlier in the same tab that has no `parent` itself; a child's `requires` equals its parent's.
- A disabled child's label uses `GameFontDisable`; re-enabled uses `GameFontHighlight`.
- Checkboxes and slider tracks have motion scripts while disabled turned on, and hovering a disabled child shows its hint. (The stub fires scripts regardless of enabled state, so the motion-scripts assertion is what guards the in-game behavior.)
- Players: Info column sits right of Header column (replaces the old two-column test).
- Missing-API rows stay hidden (kept).
- Defaults button resets values on unbuilt tabs too, forwards changes, refreshes built widgets and re-applies children's disabled state.
- Existing slider tests (steps, percent, same-row X/Y, label width, change forwarding) kept.
- `tests/integration/test_toc_load_order.lua` passes with `Settings/Widgets.lua` in the TOC.

## Docs

- `CHANGELOG.md` under `## [Unreleased]`: one player-facing line about the tabbed options with hover help.
- `SPEC.md` Settings section: one line saying the panel is tabbed (General, Players, NPCs, Look, Combat), builds each tab on first view, and shows a hover hint per option.
- `.pkgmeta` `ignore:` already lists `docs` (uncommitted in the working tree) so this spec never ships — commit it with this work, don't add it twice.
