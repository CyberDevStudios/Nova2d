# Best Practices

## Code conventions

- Use `camelCase` for variables and functions
- Use `PascalCase` for entity and system modules
- Use `local` everywhere — no global variables
- Keep strict separation between `update(dt)` (logic) and `draw()` (rendering)
- One file per module, each file returns a table

## State management

- Keep initialization in `enter()`, not at module level
- Use `Gamestate.push/pop` for overlays (pause menus)
- Use `Gamestate.switch` for normal navigation
- Use `keyreleased()` for single key presses, not `love.keyboard.isDown()`

## Entities

- Prefer composition over inheritance
- Keep `update()` focused on logic, `draw()` on rendering only
- Pass `dt` for frame-independent movement
- Use `self` for entity state

## Project structure

```
my-game/
├── main.lua              -- Do not modify
├── conf.lua              -- Window settings
├── nova2d.lua            -- Dependencies
├── src/
│   ├── states/           -- Screen modules
│   ├── entities/         -- Game objects
│   ├── systems/          -- Physics, audio, collisions
│   ├── utils/            -- Helper functions
│   └── hotreload.lua     -- Hot reload bootstrapper (do not modify)
├── assets/
│   ├── images/           -- Sprites and textures
│   ├── sounds/           -- Audio files
│   └── fonts/            -- Typefaces
└── libs/                 -- Managed by gestor
```

## Performance

- Preload assets in `love.load()` or state `enter()`
- Avoid creating new objects in `update()` — reuse tables
- Use `local` references for frequently accessed globals
- Profile with `lovebird` before optimizing
