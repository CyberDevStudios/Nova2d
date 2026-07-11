<p align="center">
  <img src="assets/images/logo.png" width="120" alt="Nova2D logo">
</p>

<h1 align="center">Nova2D</h1>

> A base framework for Love2D that standardizes project structure, dependency management, and development tooling for 2D games in Lua.

## Quick Start

```bash
# One command — no git needed
# (use Git Bash on Windows — PowerShell's curl is an alias for Invoke-WebRequest)
curl -fsSL https://nova2d.pages.dev/install.sh | bash -s my-game
cd my-game
love .
```

> **Windows users**: PowerShell has a built-in `curl` alias that maps to `Invoke-WebRequest` and won't work with this script. Use **Git Bash** (comes with Git for Windows), WSL, or the manual clone below.

Or clone manually:

```bash
git clone https://github.com/CyberDevStudios/Nova2d.git my-game
cd my-game
love .
```

## Project Status

| Phase | Status |
|---|---|
| **v0.1** — Base structure + 5 states | Complete |
| **v0.2** — Dependency manager (gestor) | Complete |
| **v0.3** — Hot reload (lurker) | Complete |
| **v0.4** — One-command installer | Complete |
| **v0.5** — Web documentation | Complete ([nova2d.pages.dev](https://nova2d.pages.dev/)) |
| **v0.6** — Core Systems (jump, health, timer, camera, input) | Released ([main](https://github.com/CyberDevStudios/Nova2d)) |
| **v1.0** — Public release | Pending |

## Requirements

- [Love2D 11.x](https://love2d.org/) (Lua 5.1)
- `curl` (for the one-command install / dependency manager)

## Features

- **5 game states** — splash (animated), menu, game, pause (overlay), credits
- **5 core systems** — input, timer, health, camera, and jump
- **Input System** — action-based key bindings with gamepad support and press buffering
- **Timer System** — countdown and stopwatch with tick/expired events
- **Health System** — HP tracking, damage, healing, invincibility frames, and death state
- **Camera System** — attach/detach with transform stacking
- **Dependency manager** — install, update, remove libraries via `nova2d.lua`
- **Hot reload** — edit `src/` files and see changes instantly (no restart)
- **One-command installer** — `curl ... | bash` setup, no git required
- **main.lua frozen** — never modify the entry point

## Project Structure

```
my-game/
├── main.lua              -- Entry point (do not modify)
├── conf.lua              -- Window configuration
├── nova2d.lua            -- Dependency manifest
├── nova2d-lock.lua       -- Auto-generated lockfile
├── src/
│   ├── states/           -- Screens (splash, menu, game, pause, credits)
│   ├── entities/         -- Player, enemies, objects
│   ├── systems/          -- Input, timer, health, camera, jump
│   ├── utils/            -- Helpers
│   └── hotreload.lua     -- Hot reload bootstrapper
├── assets/
│   ├── images/           -- Sprites, textures
│   ├── sounds/           -- Sound effects
│   └── fonts/            -- Fonts
├── libs/                 -- External dependencies (managed by gestor)
├── gestor/               -- Dependency manager tool
└── openspec/             -- SDD artifacts (specs, designs, tasks)
```

## Screens

| Screen | Description |
|---|---|
| **Splash** | Animated title with particle effects, auto-transitions after 3s or skip with any key |
| **Main Menu** | New Game, Credits, Quit — keyboard and mouse navigation |
| **Game** | Empty placeholder ready for your game code |
| **Pause** | Semi-transparent overlay, toggled with Escape |
| **Credits** | Included libraries and their authors |

## Included Libraries

| Library | Purpose | Added |
|---|---|---|
| **hump.gamestate** | Screen and scene management | v0.1 |
| **bump.lua** | AABB collision detection | v0.2 |
| **anim8** | Sprite animations | v0.2 |
| **lovebird** | In-browser debug panel | v0.2 |
| **lurker** | Hot reload | v0.3 |

## Conventions

- `camelCase` for variables and functions
- `PascalCase` for entities and systems
- `local` everywhere, no globals except `Gamestate`
- Strict separation: `update(dt)` for logic, `draw()` for rendering
- One file per module, each file returns a table

## License

MIT
