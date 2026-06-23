# Hot Reload

Hot reload lets you edit your code and see changes instantly without restarting the game. This is powered by **lurker**.

> Note: Hot reload (v0.3) is in development. This page describes the planned integration.

## How it works

Lurker watches your `src/` directory for file changes. When you save a file, it reloads the module and re-runs your game logic — no restart needed.

## Setup

Once available, hot reload is enabled by default. Just run:

```bash
love .
```

And edit files in `src/` — changes apply the moment you save.

## What gets reloaded

- State modules (splash, menu, game, etc.)
- Entity modules
- System modules
- Utils

## What does NOT reload

- `main.lua` (frozen, not meant to be edited)
- `conf.lua` (requires restart)
- `libs/` (external libraries)

## Best practices for hot reload

- Keep state in `enter()` — not in module-level variables
- Avoid `require` at the top level of frequently reloaded modules
- Use local variables inside functions for per-frame state
