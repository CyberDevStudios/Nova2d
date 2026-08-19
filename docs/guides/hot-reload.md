# Hot Reload

Add hot reload to your Love2D project and see Lua changes instantly — no restarting the game. Nova2D uses **lurker** for this.

> Status: v0.3 — available since 2026-06-22.

## Setup

Hot reload works out of the box. Just run your game:

```bash
love .
```

Edit any file in `src/` and save. The changes apply instantly.

## How it works

Lurker watches your `src/` directory for file changes. When you save a file, it reloads the Lua module and re-runs the relevant callbacks.

The patching happens **deferred** — lurker's `love.update` wrapper is installed from `splash.enter()`, which runs after `Gamestate.registerEvents()` has set up hump's callback dispatcher. This avoids the common pitfall of capturing a nil `love.update` during module loading (`require`).

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

## Adding Hot Reload to an Existing Project

If you're bringing hot reload into a vanilla Love2D project, you need three things: lurker on the require path, `lurker.update()` called once per frame, and a way to reload modules. In a Nova2D project, all three are handled for you.

### Vanilla Love2D: manual lurker setup

Add lurker to your project (e.g. under `libs/`), then require it and poll it every frame:

```lua
-- main.lua
local lurker = require("lurker")
lurker.path = "src"          -- watch your source directory

function love.update(dt)
    lurker.update()
    -- ...your game logic
end
```

`lurker.update()` checks the watched directory for changes and reloads anything that was saved. Calling it at the top of `love.update(dt)` guarantees fresh code runs the same frame a file is saved.

### The module reload pattern

Lurker forces `require()` to re-execute a module by clearing its entry from `package.loaded`; the next `require` returns the new code. This only works when modules are pure definitions:

```lua
-- Good: state lives on instances, created at runtime
local Player = {}
function Player:enter(instance)
    instance.x = 0
end
return Player

-- Bad: state lives at module level, lost on every reload
local x = 0
local Player = {}
function Player:update()
    x = x + 1
end
return Player
```

Keep per-game state in instance tables created inside `enter()`/`love.load()` — not in module-level variables — and reloading stays safe.

> **Note:** `main.lua` and `conf.lua` never hot reload in Love2D — they run once at boot. Code that must change there still requires a restart.

### The Nova2D flow

In a Nova2D project you don't write any of this. Lurker is a declared dependency:

```lua
-- nova2d.lua
return {
    name    = "my-game",
    version = "1.0.0",
    author  = "Your Name",

    dependencies = {
        ["lurker"] = {
            repo = "rxi/lurker",
            version = "master",
            type = "multi"
        },
    },
}
```

Install it with the dependency manager:

```bash
love gestor/ install
```

Nova2D's `src/hotreload.lua` bootstraps lurker (sets `lurker.path = "src"` and patches `love.update`) from the splash state's `enter()` — which runs after `Gamestate.registerEvents()`, so the callback wiring stays correct and `main.lua` stays frozen. Save a file in `src/` and the change applies instantly.

## How lurker works (technical)

Lurker polls the filesystem for changes and uses `package.loaded[mod] = nil` to force Lua's `require()` to re-execute the module. It then re-calls the appropriate Love2D callbacks with the new code.
