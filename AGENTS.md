# MouseOverTooltip

Minimal mouseover unit tooltip for World of Warcraft: Retail, the Classic flavors (Vanilla, TBC, Wrath, Cata, Mists) and WoW: Forever. One TOC (`MouseOverTooltip.toc`) carries every flavor's `## Interface-*` line.

**`SPEC.md` is the feature contract** — what lines exist, their defaults, and the performance rules. Read it before any change.

## Selling point: performance

CPU, memory and addon size come first. Every change must keep the SPEC performance rules:

- No persistent `OnUpdate` handlers (drag-only handlers removed on drop are fine). No libraries.
- Register events only while needed; unregister after.
- A disabled setting costs zero API calls.
- Caches are capped and session-only.
- WoW 12.x secret values: guard with `issecretvalue` before comparing/concatenating/indexing; skip the line instead of erroring.

If a feature can't be done within these rules, stop and ask — don't quietly break one.

## Tech Stack

- **Lua 5.1** (WoW runtime) — no Lua 5.2+ features (no `goto`, no `table.unpack` without compat)
- **WoW API** — Blizzard's frame/widget system, C\_ namespaced APIs
- **Flavor differences** go through `Core/FlavorCompat.lua` — never assume a Retail-only API exists
- **StyLua** — formatter (`stylua.toml`)
- **Luacheck** — static analysis (`.luacheckrc`)

## Code Conventions

- **2-space indentation, spaces** (not tabs)
- **PascalCase** for modules: `InspectCache`, `MythicPlus`
- **camelCase** for functions/variables: `buildLines`, `formatRating`
- **Module pattern**: every file starts with `local addonName, ns = ...` plus the `if type(ns) ~= "table" then ns = {} end` guard, and ends with `ns.ModuleName = ModuleName; return ModuleName`
- **Prefix unused args with `_`**: `_self`, `_event`
- **Access WoW globals via `_G.`**: `_G.CreateFrame`, `_G.C_PlayerInfo` — keeps the dependency on globals explicit and testable

## Linting

```bash
bash scripts/lint.sh        # check (CI-safe)
bash scripts/lint.sh --fix  # auto-format + check
```

Luacheck handles semantics, StyLua handles formatting. Both must pass clean — they are the only lint gates CI runs.
Missing tools on Windows: `powershell -ExecutionPolicy Bypass -File scripts/setup-lint-tools.ps1` installs them into `.tools/`.
When adding new WoW API globals, add them to `.luacheckrc` under `read_globals`.

## Tests

```bash
lua tests/run.lua tests/path/to/test_file.lua          # if lua is available
python scripts/run_test.py tests/path/to/test_file.lua # Windows fallback (pip install lupa)

# all tests
for f in tests/**/test_*.lua; do lua tests/run.lua "$f"; done
```

Tests run with plain Lua — no WoW runtime. WoW APIs are stubbed in `tests/helpers/`.
The release pipeline minifies the shipped Lua and re-runs every test on the minified code, so neither code nor tests may depend on comments or exact source formatting.

## Development Workflow — TDD (Red-Green-Refactor)

1. **Red** — write a failing test first; confirm it fails for the right reason.
2. **Green** — minimum code to pass; confirm.
3. **Refactor** — clean up; run all tests; run `bash scripts/lint.sh`.

- **Never write production code without a failing test that demands it.**
- **One behavior per test**, named for the behavior: `test_mythic_line_shows_best_key_level`.
- **Test file mirrors source file** — `Data/MythicPlus.lua` → `tests/data/test_mythic_plus.lua`.

## File Size & Modularity

- Target ~300 lines per file; one responsibility per file; applies to tests too.

## Adding a File

- **Add it to `MouseOverTooltip.toc`, after everything it depends on.** TOC order is load order. WoW: Forever has a global `require` that throws "Invalid import", so a module's `ns.X or require(...)` fallback must never be reached in game. `tests/integration/test_toc_load_order.lua` guards this.
- **New top-level files that aren't addon code** (docs, configs) go in `.pkgmeta` `ignore:` so they don't ship.

## Localization

English only for now. Every player-visible string goes through `Localization.Text("English text")` — the English text is the key, so adding `Locale/<code>.lua` catalogs later needs no call-site changes.

## Lua Best Practices

- Localize everything; localize hot-path API calls at file top (`local pairs = pairs`).
- Avoid tables in tight loops; `table.concat` for string building.
- `ipairs` for arrays, `pairs` for dictionaries.
- Nil-check before method calls — frames may lack methods in test stubs.
- No global leaks. Early returns over nesting. No magic numbers — local `UPPER_CASE` constants.
- Keep functions under ~40 lines.

## Changelog

`CHANGELOG.md` is **player-facing release notes** (CurseForge / Wago readers), not an engineering log.

- Plain English, describe the in-game effect. No file paths, module/function/API names, Lua terms, "refactor".
- One bullet per user-visible change. Fixes start with `Fixed:`.
- Always add a line under `## [Unreleased]` in the same turn as a behavior/UI/settings change.

## Releasing

1. Notes sit under `## [Unreleased]`, working tree clean.
2. `bash scripts/release.sh <version>` — needs internet (reads live game versions from Blizzard). Promotes notes, bumps TOC + `Core/Constants.lua`, commits and tags.
3. `git push origin master v<version>` — CI lints, minifies, re-runs tests, uploads to CurseForge, Wago and GitHub Releases.

## Project Structure

```
Bootstrap.lua   — Addon entry point (last file in the TOC)
Core/           — Flavor compat, constants, localization, slash command, secret-value guards
Data/           — API readers: inspect queue + cache, M+, mount, quests, PvP, group, friends
Tooltip/        — Line builders, anchor, combat hiding, health bar, borders
Settings/       — Defaults, saved state, Options → AddOns panel
UI/             — Minimap button
tests/          — Unit and integration tests (mirror the source folders)
scripts/        — Lint, test runner, release, packaging
```
