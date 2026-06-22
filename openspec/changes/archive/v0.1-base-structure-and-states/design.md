# Design: v0.1 — Base Structure + States

## Technical Approach

Five-state FSM driven by `hump.gamestate`, with Love2D callbacks proxied via `Gamestate.registerEvents()`. `main.lua` is a frozen framework orchestrator — it requires all states, registers hump, and starts the Splash state. `conf.lua` configures the window. Each state is a self-contained Lua module under `src/states/`. Transitions use `Gamestate.switch()`.

## Architecture Decisions

### hump.gamestate as state engine

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Custom FSM | More control, more maintenance | ❌ |
| hump.gamestate | Proxies all callbacks, battle-tested, transition queue | ✅ |

### Do-not-modify main.lua

| Option | Tradeoff | Decision |
|--------|----------|----------|
| User owns main.lua | Flexible, but every project reimplements the same wiring | ❌ |
| Framework owns main.lua | Frozen contract across all Nova2D projects | ✅ |

### Pause as overlay, not freeze

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Pause stops Game updates | Clean break but kills animations/timers running behind | ❌ |
| Pause overlays, Game keeps updating | Game state continues rendering behind overlay | ✅ |

### Programmatic logo as fallback

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Pre-committed PNG | Needs external tooling to generate | ❌ |
| Base64-inline PNG | Bloats .lua with binary data | ❌ |
| Love2D canvas render at runtime | Zero external deps, purely code | ✅ |

## Module Dependency Graph

```
love [.run loop]
  │
  ├─ conf.lua                      (no deps)
  ├─ main.lua                      (frozen, do not modify)
  │    ├─ require "hump.gamestate"
  │    ├─ require "src.states.splash"
  │    ├─ require "src.states.menu"
  │    ├─ require "src.states.game"
  │    ├─ require "src.states.pause"
  │    └─ require "src.states.credits"
  │
  └─ src/states/*.lua              (each requires hump.gamestate for Gamestate.switch)
       └─ libs/hump/gamestate.lua  (single-file lib, no sub-deps)
```

**No circular deps.** States import Gamestate but never import each other — they pass the target state table to `Gamestate.switch()` by requiring it at call site.

## Data Flow

```
love.run (Love2D built-in loop)
  │
  ├─ love.load()
  │   └─ main.lua:
  │        Gamestate.registerEvents()      -- proxies love.update/draw/key/... to active state
  │        Gamestate.switch(splash)         -- starts the FSM
  │
  ├─ love.update(dt)
  │   └─ Gamestate.update(dt)
  │       └─ active_state:update(dt)
  │            [Splash: countdown 3→0]
  │            [Menu:   nothing]
  │            [Game:   nothing]
  │            [Pause:  nothing (Game still runs in stack)]
  │
  └─ love.draw()
      └─ Gamestate.draw()
          └─ active_state:draw()
               [Splash: centered logo + fallback text]
               [Menu:   title + highlighted options]
               [Pause:  game behind + semi-transparent overlay]
```

Transitions: `Gamestate.switch(target)` calls `current:leave()` → `target:enter(previous)`. hump queues rapid transitions to avoid race conditions.

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `main.lua` | Create | Orchestrator: require all modules, register hump, boot Splash |
| `conf.lua` | Create | Window: 800×600, resizable, vsync, title "Nova2D" |
| `nova2d.lua` | Create | Stub dep manifest (v0.2 gestor) |
| `nova2d-lock.lua` | Create | Stub lockfile (v0.2 gestor) |
| `src/states/splash.lua` | Create | Logo + 3s timer → Menu |
| `src/states/menu.lua` | Create | 3 options, KB + mouse input |
| `src/states/game.lua` | Create | Empty placeholder state |
| `src/states/pause.lua` | Create | Esc toggle, overlay only |
| `src/states/credits.lua` | Create | Library list, return nav |
| `src/entities/` | Create | Empty dir |
| `src/systems/` | Create | Empty dir |
| `src/utils/` | Create | Empty dir |
| `assets/images/` | Create | Asset dir (contains logo placeholder) |
| `assets/sounds/` | Create | Empty dir |
| `assets/fonts/` | Create | Empty dir |
| `libs/hump/gamestate.lua` | Create | hump single-file state lib |

## Interfaces / Contracts

### main.lua

```lua
-- FROZEN FILE — do not modify.
local Gamestate = require "hump.gamestate"
local splash    = require "src.states.splash"
-- ... require the other 4 states

function love.load()
    Gamestate.registerEvents()  -- proxies love.update/draw/keyreleased/mousepressed
    Gamestate.switch(splash)
end
```

No `love.update()` or `love.draw()` in main.lua — Gamestate handles them.

### conf.lua

```lua
function love.conf(t)
    t.identity = "nova2d"
    t.window.title = "Nova2D"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.window.vsync = 1
    t.modules.audio = false
    t.modules.physics = false
    t.modules.joystick = false
end
```

**800×600**: Love2D-friendly default. **Resizable**: dev ergonomics. **vsync=1**: prevents tearing during transitions. **Disable audio/physics/joystick**: minimize loop overhead in v0.1.

### State module contract

Every state returns a table with optional callbacks that hump.gamestate routes to:

```lua
local State = {}
function State:enter(previous) end      -- optional setup
function State:update(dt) end           -- per-frame logic
function State:draw() end               -- per-frame render
function State:keyreleased(key) end     -- keyboard
function State:mousepressed(x,y,btn) end-- mouse
return State
```

### Splash: timer + logo

```lua
-- Internal state
local logo, timer

function State:enter()
    local ok, img = pcall(love.graphics.newImage, "assets/images/logo.png")
    logo = ok and img or nil
    timer = 3
end

function State:update(dt)
    timer = timer - dt
    if timer <= 0 then
        Gamestate.switch(require("src.states.menu"))
    end
end

function State:draw()
    if logo then
        local sx = math.min(400 / logo:getWidth(), 300 / logo:getHeight())
        love.graphics.draw(logo, 400, 300, 0, sx, sx, logo:getWidth()/2, logo:getHeight()/2)
    else
        love.graphics.printf("Nova2D", 0, 280, 800, "center")
    end
end
```

### Menu: data structures + input

```lua
local menuItems = {
    { label = "New Game", action = function() Gamestate.switch(game) end },
    { label = "Credits",  action = function() Gamestate.switch(credits) end },
    { label = "Quit",     action = function() love.event.quit() end },
}
local selected = 1  -- 1-based

-- Hardcoded Y offsets for mouse hit detection: 350, 400, 450

function State:keyreleased(key)
    if key == "up" then selected = math.max(1, selected - 1)
    elseif key == "down" then selected = math.min(#menuItems, selected + 1)
    elseif key == "return" or key == "space" then menuItems[selected].action()
    elseif key == "escape" then love.event.quit()
    end
end

function State:mousepressed(x, y, button)
    if button ~= 1 then return end
    local itemY = { 350, 400, 450 }
    for i, cy in ipairs(itemY) do
        if y >= cy - 20 and y <= cy + 20 then
            selected = i
            menuItems[i].action()
            return
        end
    end
end
```

Both input methods work simultaneously — no mode switching.

### Pause: overlay, not stop

```lua
function State:enter(previous)
    self.previous = previous  -- save to resume
end
-- update(dt) intentionally empty — Game state runs via Gamestate stack

function State:draw()
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, 250, 800, "center")
    love.graphics.printf("Press ESC to resume", 0, 300, 800, "center")
end

function State:keyreleased(key)
    if key == "escape" then
        Gamestate.switch(self.previous or require("src.states.game"))
    end
end
```

### Credits: library listing

```lua
local credits = {
    { lib = "hump.gamestate", author = "vrld" },
}

function State:draw()
    love.graphics.printf("Credits", 0, 100, 800, "center")
    local y = 200
    for _, entry in ipairs(credits) do
        love.graphics.printf(entry.lib .. " by " .. entry.author, 0, y, 800, "center")
        y = y + 40
    end
    love.graphics.printf("ESC/Enter/Click to return", 0, 500, 800, "center")
end

function State:keyreleased(key)
    if key == "escape" or key == "return" or key == "backspace" then
        Gamestate.switch(require("src.states.menu"))
    end
end
```

### nova2d.lua / nova2d-lock.lua — stubs

```lua
-- nova2d.lua
-- Dependency manifest for the Nova2D gestor (v0.2+).
return {}
```

```lua
-- nova2d-lock.lua
-- Auto-generated. Do not edit.
return {}
```

## hump Integration Design

- **Files**: Only `gamestate.lua` — hump is single-file for its state module.
- **Directory**: `libs/hump/gamestate.lua` — flat structure, no subdirs.
- **Version pin**: Commit `84ae1ff` from `vrld/hump` (v0.4). Record in `libs/hump/VERSION` text file.
- **Other hump modules** (timer, vector, camera): NOT included. Only gamestate is needed for v0.1. Add others as needed in later versions.

## Logo Placeholder Strategy

**Recommendation**: Generate at runtime via Love2D canvas.

```lua
-- In splash.lua enter(), after pcall fallback:
if not logo then
    local canvas = love.graphics.newCanvas(400, 200)
    love.graphics.setCanvas(canvas)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("NOVA2D", 0, 60, 400, "center")
    love.graphics.setCanvas()
    logo = love.graphics.newImage(canvas:newImageData())
end
```

This creates a crisp text-based logo without any external PNG. If the user drops their own `assets/images/logo.png`, it takes priority. The canvas approach works at runtime but doesn't persist — users who want a permanent placeholder can include one.

**Alternative for distribution**: Generate a minimal PNG (e.g., 1×1 transparent pixel) committed to `assets/images/logo.png` so `love.filesystem` can find it without canvas hacks. The canvas fallback handles the case where the PNG is missing.

## Error Handling Strategy

| Scenario | Approach |
|----------|----------|
| Logo PNG missing/corrupt | `pcall()` → canvas fallback, never crash |
| hump missing | Lua `module not found` error (descriptive, includes file path) |
| State module missing | Lua `module not found` at `require` — clear stack trace |
| Nil callback on state | hump.gamestate doesn't error on missing callbacks (no-op) |
| Love2D version mismatch | Handled by conf.lua's module toggles |

**Lua 5.1 nil guards**: `value or default` for optional fields. Always check `if var` before indexing. Use `pcall()` for all asset loads.

## Constants and Configuration

| Value | Location | Why |
|-------|----------|-----|
| 800×600 window | `conf.lua` | Proposal requirement |
| 3s splash | `splash.lua` local | Proposal requirement |
| Menu item Y positions | `menu.lua` local | Fixed 3-item layout |
| Pause alpha 0.6 | `pause.lua` local | Visual preference |
| Credits list | `credits.lua` local | Only 1 entry in v0.1 |

**No shared constants module for v0.1.** All values are local to their scope. Extract to `src/utils/constants.lua` only when v0.2+ demonstrates a need.

## State Transition Diagram

```
[Splash] ──(3s timer)──→ [Menu] ──(New Game)──→ [Game] ──(Esc)──→ [Pause]
                             │                      ↑                    │
                        (Credits)                    └──(Esc)────────────┘
                             │
                             ↓
                        [Credits] ──(Esc/Enter/click)──→ [Menu]
```

Every transition uses `Gamestate.switch(target)`. No animation/fade in v0.1 (instant transitions).

## Testing Strategy

| Layer | What | How |
|-------|------|-----|
| Visual | All 5 states | `love .` — verify each screen renders |
| Transitions | All 6 state transitions | Manual navigation through every path |
| Input | KB + mouse on Menu | Navigate with keys, click with mouse |
| Edge | Logo missing | Delete logo.png, verify text fallback renders |
| Edge | Rapid key presses | Spam Enter/Esc during transitions, verify no crash |

No automated test infrastructure for v0.1. Pure Lua/Love2D lacks a standard test runner. Manual verification against the proposal's success criteria.

## Migration / Rollout

No migration — clean slate project. Rollback = delete all created files.

## Open Questions

None. All decisions resolved in proposal.
