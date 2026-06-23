# Architecture

Nova2D is structured as a modular Lua framework on top of Love2D 11.x. It separates game runtime code from development tooling.

## High-level structure

```
my-game/
├── main.lua              -- Frozen entry point
├── conf.lua              -- Window configuration
├── nova2d.lua            -- Dependency manifest
├── nova2d-lock.lua       -- Auto-generated lockfile
├── src/                  -- Game source code
│   ├── states/           -- Screen modules
│   ├── entities/         -- Game objects
│   ├── systems/          -- Physics, audio, collisions
│   ├── utils/            -- Helpers
│   └── hotreload.lua     -- Lurker bootstrapper (deferred patch)
├── assets/               -- Game assets
│   ├── images/
│   ├── sounds/
│   └── fonts/
├── libs/                 -- Installed dependencies
├── gestor/               -- Dependency manager tool
└── docs/                 -- Documentation
```

## Runtime vs tooling

The game runtime (`main.lua`, `src/`, `assets/`, `libs/`) is completely separate from development tooling (`gestor/`, `docs/`, `openspec/`). This means:

- The dependency manager doesn't affect game performance
- You can delete `gestor/` in a release build
- Documentation can be served separately

## Lifecycle

```
love .
  │
  ├── conf.lua          ← Settings applied first
  │
  ├── main.lua          ← Gamestate.registerEvents()
  │                           │
  └── Gamestate          ← Routes callbacks to active state
        │
        ├── Splash       ← 3s auto / any key → Menu
        ├── Menu         ← User selects → Game / Credits / Quit
        ├── Game         ← Your game code
        ├── Pause        ← Esc overlay via push/pop
        └── Credits      ← Esc/click → Menu
```

## Modules

| Layer | Technology | Purpose |
|---|---|---|
| State machine | hump.gamestate | Screen transitions and lifecycle |
| Rendering | Love2D 11.x | GPU-accelerated 2D graphics |
| Input | Love2D callbacks | Keyboard and mouse handling |
| Dependency mgmt | gestor (custom) | Install, update, remove libs |
| Hot reload | lurker (v0.3+) | Live code reloading |
| Debug | lovebird (v0.2+) | Browser-based debug panel |
