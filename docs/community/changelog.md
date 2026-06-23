# Changelog

## v0.2 — Dependency Manager (2026-06-22)

- Added `gestor/` directory with headless dependency manager
- 5 CLI commands: install, update, remove, list
- Single-file and multi-file (ZIP) download support
- Lockfile with atomic writes and UNIX timestamps
- Automatic version detection via GitHub API
- OS-specific tool detection with install instructions
- `nova2d.lua` populated with 5 real dependencies

## v0.4 — Curl Installer (2026-06-22)

- Added `install.sh` — one-command setup via `curl ... | bash`
- OS detection: Linux, macOS, WSL, Git Bash
- Love2D detection with OS-specific install instructions
- Downloads latest release via GitHub API (falls back to archive)
- Creates project structure and installs default dependencies
- No dependencies beyond curl and Love2D

## v0.3 — Hot Reload (2026-06-22)

- Added `src/hotreload.lua` bootstrapper for lurker
- Hot reload active on all `src/` files (states, entities, systems, utils)
- No modifications to `main.lua` (frozen contract maintained)
- Error recovery via lurker's protected mode
- 0.5s scan interval for file changes

## v0.1 — Base Structure + States (2026-06-22)

- Project skeleton with directory structure
- 5 game states: splash, menu, game, pause, credits
- hump.gamestate integration
- Keyboard and mouse navigation
- Headless Love2D configuration
- Placeholder Nova2D logo
