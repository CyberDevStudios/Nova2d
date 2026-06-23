# Changelog

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
- Placeholder Nova2D logo
