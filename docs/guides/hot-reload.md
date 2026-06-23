# Hot Reload

Hot reload lets you edit your source code and see changes instantly without restarting the game. Nova2D uses **lurker** for this.

> Status: v0.3 — available since 2026-06-22.

## How it works

Lurker watches your `src/` directory for file changes. When you save a file, it reloads the Lua module and re-runs the relevant callbacks. No restart needed.

## Setup

Once v0.3 is implemented, hot reload works out of the box. Just run your game:

```bash
love .
```

Edit any file in `src/` and save. The changes apply instantly.

## What gets reloaded

| Directory | Reloads? | Notes |
|---|---|---|
| `src/states/` | Yes | State modules reload on save |
| `src/entities/` | Yes | Entity modules reload on save |
| `src/systems/` | Yes | System modules reload on save |
| `src/utils/` | Yes | Utility modules reload on save |
| `main.lua` | No | Frozen entry point |
| `conf.lua` | No | Requires full restart |
| `libs/` | No | External libraries |

## Best practices for hot reload

- Keep state in `enter()` callbacks, not in module-level variables
- Avoid `require` at the top level of frequently-reloaded modules
- Use local variables inside functions for per-frame state
- If a module doesn't reload, touch the file again or restart `love .`

## How lurker works (technical)

Lurker polls the filesystem for changes and uses `package.loaded[mod] = nil` to force Lua's `require()` to re-execute the module. It then re-calls the appropriate Love2D callbacks with the new code.
