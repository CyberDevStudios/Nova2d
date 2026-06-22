# Nova2D

> Base framework for Love2D that standardizes structure, dependency management, and development tooling for 2D games in Lua.

## Project Status

| Phase | Status |
|---|---|
| **v0.1** — Base structure + states | Complete |
| **v0.2** — Dependency manager | In progress |
| **v0.3** — Hot reload | Pending |
| **v0.4** — Installer | Pending |
| **v0.5** — Web documentation | Pending |
| **v1.0** — Public release | Pending |

## Requirements

- [Love2D 11.x](https://love2d.org/) (Lua 5.1)
- `curl` (for the dependency manager, v0.2+)

## Quick Start

```bash
git clone https://github.com/MatFon73/Nova2d.git my-game
cd my-game
love .
```

You'll see the Nova2D splash, main menu, and an empty game screen ready to build upon.

## Project Structure

```
my-game/
├── main.lua              -- Entry point (do not modify)
├── conf.lua              -- Window configuration
├── nova2d.lua            -- Project dependencies
├── nova2d-lock.lua       -- Auto-generated lockfile
├── src/
│   ├── states/           -- Screens (splash, menu, game, pause, credits)
│   ├── entities/         -- Player, enemies, objects
│   ├── systems/          -- Physics, audio, collisions
│   └── utils/            -- Helpers
├── assets/
│   ├── images/           -- Sprites, textures
│   ├── sounds/           -- Sound effects
│   └── fonts/            -- Fonts
└── libs/                 -- External dependencies
    └── hump/             -- Gamestate management
```

## Screens (v0.1)

| Screen | Description |
|---|---|
| **Splash** | Nova2D logo, auto-transitions after 3s |
| **Main Menu** | New Game, Credits, Quit — keyboard and mouse navigation |
| **Game** | Empty placeholder ready for your game |
| **Pause** | Semi-transparent overlay, toggled with Escape |
| **Credits** | Included libraries and their authors |

## Conventions

- `camelCase` for variables and functions
- `PascalCase` for entities and systems
- `local` everywhere where possible
- Strict separation between `update()` (logic) and `draw()` (rendering)
- One file per entity or system

## Included Libraries

| Library | Purpose |
|---|---|
| **hump.gamestate** | Screen and scene management |
| **bump.lua** (v0.2+) | AABB collision detection |
| **anim8** (v0.2+) | Sprite animations |
| **lurker** (v0.3+) | Hot reload |
| **lovebird** (v0.2+) | In-browser debug panel |

## License

MIT
