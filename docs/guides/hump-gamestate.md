# Hump Gamestate vs Nova2D State Machine

Hump Gamestate is the de-facto state manager for Love2D — it routes callbacks to the active state table, with `switch`, `push`/`pop`, and `enter`/`leave` lifecycle hooks. Nova2D wraps hump.gamestate into its State Machine: the same familiar API (`switch`, `push`, `pop`, `current`) plus typed per-state callbacks, wired to Love2D automatically.

## Hump Gamestate (vanilla)

Gamestate treats each screen (menu, game, pause) as a table with lifecycle callbacks. You register the callbacks once, then switch between states:

```lua
local Gamestate = require("hump.gamestate")

local Menu = {}
function Menu:enter(previous)   self.selected = 1  end
function Menu:update(dt)        -- per-frame logic  end
function Menu:draw()            -- rendering       end
function Menu:leave()           -- cleanup         end

function love.load()
    Gamestate.registerEvents()   -- routes love.* callbacks to the active state
    Gamestate.switch(Menu)
end
```

Navigation uses the state stack:

```lua
Gamestate.switch(game)          -- replace the current state
Gamestate.push(pause)           -- overlay on top (game keeps updating below)
Gamestate.pop()                 -- back to the previous state
local current = Gamestate.current()
```

`registerEvents()` is what makes it feel native: after it runs, `love.update`, `love.draw`, `love.keypressed`, etc. are delegated to the active state's callbacks automatically.

## The Nova2D State Machine

Nova2D exposes hump.gamestate as the global `Gamestate` and wires it from `main.lua` — you never call `registerEvents()` yourself. You only write state modules:

```lua
-- src/states/menu.lua
local Menu = {}

function Menu:enter(previous)
    self.selected = 1
end

function Menu:update(dt)
end

function Menu:draw()
    love.graphics.printf("Menu", 0, 280, 800, "center")
end

function Menu:keyreleased(key)
    if key == "escape" then
        Gamestate.switch(game)
    end
end

return Menu
```

Switching, pushing and popping are identical to hump:

```lua
Gamestate.switch(game, score, level)   -- extra args reach enter(previous, ...)
Gamestate.push(pause)
Gamestate.pop()
local active = Gamestate.current()
```

> **Note:** Nova2D's `main.lua` is frozen — the `Gamestate.registerEvents()` call and the initial `Gamestate.switch(splash)` are already there. Your states live in `src/states/` and are `require`d by path, e.g. `require("src.states.menu")`.

## Vanilla → Nova2D

| Feature | hump.gamestate (vanilla) | Nova2D State Machine |
|---|---|---|
| Switch states | `Gamestate.switch(state, ...)` | Same — `Gamestate` exposed as a global |
| Overlays | `Gamestate.push(state)` / `pop()` | Same |
| Active state | `Gamestate.current()` | Same |
| Callback routing | `Gamestate.registerEvents()` in `love.load` | Done automatically by `main.lua` |
| State callbacks | `enter` / `leave` / `update` / `draw` + registered love callbacks | Same, plus typed callbacks (`keypressed`, `mousepressed`, `resize`) |
| State layout | Any tables you manage yourself | Convention: one module per state in `src/states/` |

## Next step

The State Machine is the core of Nova2D's flow: states in `src/states/`, callbacks wired automatically, overlays via `push`/`pop`. See the [State Machine API](../api/state-machine.md) for the full reference — transitions, state stack behavior, and every state callback.