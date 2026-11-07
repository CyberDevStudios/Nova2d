# Changelog

Every release of Nova2D, from the initial v0.1 base structure to the latest core systems. Each entry lists new features, bug fixes, and breaking changes so you can plan upgrades with confidence.

## v0.8.0 — EntityManager, Demo, Tests & CI (2026-11-06)

- **EntityManager** (`src/systems/entitymanager.lua`) — entity registry with `add`/`remove`, deferred removal (safe inside update loops), `clear`/`reset`, layer-based update/draw order, `tags` + `getByTag`/`query`, `added`/`removed` events, and system composition through `attach`/`detach` (systems update before the entity)
- **Playable platformer demo** — `src/states/game.lua`, `src/entities/player.lua` and `src/entities/hazard.lua` wire Input, Jump, Collision, Health, Camera, Animation and EntityManager into a complete level with spikes, i-frames, pit respawn, HP HUD and camera shake
- **Entity pattern corrected** — all entity docs now use the metatable constructor (`Player.new(x, y)`), matching the built-in systems; the old blueprint / DOT-syntax pattern is gone
- **Fixed config merge in systems** — `jump`, `health`, `timer` and `camera` used `config[k] ~= nil and config[k] or default`, which silently dropped `false` values (`variableHeight = false`); constructors now use an explicit nil-check
- **Fixed `camera.new({ bounds = ... })`** — `bounds` was never copied from the config
- **Fixed menu input and hitboxes** — menu/pause/credits use `keypressed` (no more repeated actions while held); mouse hitboxes match the drawn buttons
- **Centralized version** — `src/version.lua` is the single source of truth; the splash screen sets the window title to `Nova2D v0.8.0`
- **Test suite** — 92 busted specs for every system, the EntityManager and the documented examples; Love2D stubs allow headless runs
- **CI** — GitHub Actions: luacheck + busted, Love2D boot smoke test under Xvfb, installer checksum guard
- **Installers** — rewritten `install.sh` (`--version`, correct `main` fallback, cleanup) and new `install.ps1`; `.gitattributes` keeps development files out of source archives; `install.sh.sha256` published
- **Docs** — new EntityManager, platformer, packaging and testing pages; installer guide covers Windows, checksums and reading before running; Quick Start, 5-minute and Pong tutorials updated to the constructor pattern
- **Hot reload** — `patch_update` is now local; splash no longer crashes on stray Windows `*:Zone.Identifier` files
- **Breaking** — entities written with the old blueprint/DOT pattern must migrate to `Module.new(...)`; `attach()` stores systems as `entity.<name>` (`player.jump`, not `player.systems.jump`)

## v0.7.0 — Core Systems II: Animation, Audio, Collision (2026-08-19)

- **Animation system** (`src/systems/animation.lua`) — sprite-sheet animation over anim8: configurable grid/fps/frames, `loop`/`flipX`/`flipY`, `frame` and `complete` events, `getQuad()` for drawing
- **Audio system** (`src/systems/audio.lua`) — channel-based audio manager: source pooling with slot stealing, per-channel and master volume, fades, `ended` and `fade-complete` events
- **Collision system** (`src/systems/collision.lua`) — AABB collision world over bump.lua: spatial hash, `move`/`check`/`query`/`queryPoint`, `collision` events with normals, automatic position write-back, plus pure `box`/`overlaps`/`contains` helpers
- **Fixed dependency naming bug** — `bump.lua` dependency renamed to `bump` in `nova2d.lua`: the gestor now installs `libs/bump/bump.lua`, making the documented `require("bump")` resolve through conf.lua paths (previously the installed path was unreachable)
- Full API documentation for each new system

## v0.6.2 — Domain Migration (2026-07-21)

- Migrated official domain from `nova2d.pages.dev` to `nova2d.dev`
- Updated install command: `curl -fsSL https://nova2d.dev/install.sh | bash`
- Updated all docs, README, AGENTS, sitemap, robots.txt, OG metadata, and LLMs.txt
- Removed `google-site-verification` meta tag (now using domain verification)
- Updated Cloudflare Pages Function ORIGIN and SSR meta injection
- Updated `game.lua` documentation text
- Removed obsolete fix-installer troubleshooting docs

## v0.6.1 — Timer Bugfix & Health API Clarity (2026-07-12)

- **Fixed critical timer bug** (`src/systems/timer.lua`) — constructor set `self.mode`/`self.duration` but methods accessed `self._mode`/`self._duration` (always nil). Fixed in `update()`, `getRemaining()`, `getProgress()`, and `isExpired()`
- **Health refactor** (`src/systems/health.lua`):
  - Renamed `self._hp` → `self._currentHp` for explicit naming
  - Renamed `getHp()` → `getCurrentHp()` — clearer intent
  - Added `setMaxHp(newMax)` — updates maxHp and re-clamps current HP
- All existing public API preserved (`getMaxHp()`, events, etc.)
- Updated docs, game state, and test file for renamed method

## v0.6.0 — Core Systems: Jump, Health, Timer, Camera, Input (2026-07-10)

- **Jump system** (`src/systems/jump.lua`) — configurable gravity, variable jump height, multi-jump, coyote time, jump buffer, event callbacks
- **Health system** (`src/systems/health.lua`) — HP tracking, damage types, invincibility frames, death/respawn state, event callbacks
- **Timer system** (`src/systems/timer.lua`) — countdown and stopwatch modes, pause/resume, frame-rate independent
- **Camera system** (`src/systems/camera.lua`) — target follow with smoothing, screen shake, zoom clamping, map bounds, `attach/detach` transforms
- **Input system** (`src/systems/input.lua`) — action-based key bindings with remapping, input buffer window, keyboard + gamepad support
- All systems follow consistent API: `new(config)` / `update(dt)` / `reset()` / `on(event, cb)`
- Zero external dependencies — pure Lua + Love2D 11.x APIs
- Full API documentation with usage examples for each system

## v0.5.4 — Gestor Overhaul & Dependency Fixes (2026-07-04)

- **Fixed all 5 dependency URLs** — GitHub tags use `v` prefix (`v3.1.7` not `3.1.7`) and default branches are `master` not `main`
- **Added `lume` as dependency** — required by lurker but wasn't listed
- **Patched lurker nil crash** — `love.filesystem.getInfo()` can return `nil` in Love2D 11.x; lurker's `isdir()` and `lastmodified()` now handle it
- **Migrated unzip to `io.popen`** — same sandbox-safe pattern as curl; `os.execute` can return `nil` in Snap/Flatpak environments
- **Fixed `os.tmpname()` conflict** — `os.tmpname()` may create a file that prevents `mkdir -p`; added `os.remove()` before creating temp dir
- **Upfront unzip check** — `love gestor/ install` now fails immediately with install instructions if `unzip` is missing and multi-file deps need it
- **`libs/` removed from git tracking** — dependencies are downloaded via gestor, no longer committed to the repo
- **Added `unzip` to prerequisites** in installer docs
- **Docs site version bump** to v0.5.4

## v0.5.3 — Installer & Gestor Hardening (2026-07-03)

- Redesigned install.sh welcome message with cleaner layout, border, and Cyber Dev Studios credit
- Fixed ANSI escape codes not rendering in welcome heredoc — switched color vars to `printf -v` for real ESC bytes
- Fixed `love gestor/` (no args) running instead of `love gestor/ install` during install_deps
- Fixed `util.get_project_root()` returning path with trailing `/gestor/` — strips trailing slashes before regex
- Fixed `util.normalize_exit_code()` crash when `os.execute` returns nil
- Fixed `util.find_tool()` not finding curl in sandboxed Love2D environments (Snap/Flatpak) — added `io.open` fallback on common paths
- Replaced Pong tutorial GIF with YouTube video embed (`<!-- youtube:snyD3X8_B5Q -->`)
- Removed redundant `love gestor/ install` line from Pong tutorial (handled by install.sh)
- Docs site: PageSpeed optimizations, YouTube embed support, llms.txt, light mode contrast fix, crawlable nav links

## v0.5.2 — Require Path Consistency (2026-07-02)

- Fixed double-instance bug in Pong tutorial caused by mixing `require("states.menu")` and
  `require("src.states.menu")` — Lua treats them as different cache keys in `package.loaded`,
  creating separate module tables with independent state
- Moved lazy `require()` calls to top-level in `src/states/splash.lua`, `game.lua`,
  `pause.lua`, and `credits.lua` for consistent module loading at init time
- `src/states/menu.lua` keeps lazy requires with explanatory comment — moving them to
  top would create circular dependencies (menu ↔ game ↔ pause and menu ↔ credits)
- Updated all documentation code examples (`tutorial-pong.md`, `states.md`, `faq.md`) to
  use the `src.` prefix convention for internal requires
- Added require path convention comment to `main.lua`

## v0.5.1 — Documentation Content (2026-07-01)

- Rewrote Quick Start with coherent step-by-step flow (steps 1–5, verifiable code)
- Expanded States docs: added entity wiring pattern, `resize` callback, data passing between states, and all Gamestate API methods with parameter tables
- Rewrote Entities docs: explains colon syntax and instance table pattern, documents `parent` parameter, multi-instance examples
- Added Pong tutorial (guides/tutorial-pong.md): 8 steps, each verifiable at runtime
- Added FAQ & Troubleshooting (guides/faq.md): 20+ entries covering install, runtime, hot reload, gestor, migration, compatibility
- Expanded API Reference: state-machine.md (switch/push/pop/current, all callbacks with typed params), entity-api.md (lifecycle with explicit parameters), configuration.md (t.identity, t.modules.audio, t.console, t.window.icon)
- Removed `master` → `main` branch rename (no longer needed)

## v0.5 — Web Documentation (2026-06-23)

- Launched documentation website at [nova2d.dev](https://nova2d.dev/)
- Full docs site structure with getting started, guides, API reference, and community pages
- One-command install URL points to production web
- Added `beta` branch for pre-release builds
- Cleaned up emojis from README and local docs
- Added `*:Zone.Identifier` to `.gitignore` for Windows compat

## v0.4 — Curl Installer (2026-06-22)

- Added `install.sh` — one-command setup via `curl ... | bash`
- OS detection: Linux, macOS, WSL, Git Bash
- Love2D detection with OS-specific install instructions
- Downloads latest release via GitHub API (falls back to archive)
- Creates project structure and installs default dependencies
- No dependencies beyond curl and Love2D
- Fixed Windows dependency download compatibility in `gestor/download.lua`: safe shell quoting, OS-aware ZIP extraction, temp cleanup, and path handling
- Fixed nil-font crashes in `src/states/pause.lua`, `src/states/menu.lua`, and `src/states/credits.lua` by adding safe font fallback logic

## v0.3 — Hot Reload (2026-06-22)

- Added `src/hotreload.lua` bootstrapper for lurker
- Deferred patching via `splash.enter()` to avoid nil `love.update` at require time
- Hot reload active on all `src/` files (states, entities, systems, utils)
- No modifications to `main.lua` (frozen contract maintained)
- 0.5s scan interval for file changes

## v0.2 — Dependency Manager (2026-06-22)

- Added `gestor/` directory with headless dependency manager
- 5 CLI commands: install, update, remove, list
- Single-file and multi-file (ZIP) download support
- Lockfile with atomic writes and UNIX timestamps
- Automatic version detection via GitHub API
- OS-specific tool detection with install instructions
- `nova2d.lua` populated with 5 real dependencies

## v0.1 — Base Structure + States (2026-06-22)

- Project skeleton with directory structure
- 5 game states: splash, menu, game, pause, credits
- hump.gamestate integration
- Keyboard and mouse navigation
- Headless Love2D configuration
- Nova2D rocket logo (FontAwesome)
