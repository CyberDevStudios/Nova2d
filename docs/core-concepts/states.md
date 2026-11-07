# States

Nova2D uses **hump.gamestate** for screen management. Each screen (state) is a separate
Lua module that returns a table with lifecycle callbacks.

## Lifecycle

| Callback | When it runs |
|---|---|
| `enter(previous, ...)` | When the state becomes active |
| `update(dt)` | Every frame while active |
| `draw()` | Every frame after update |
| `keyreleased(key)` | On key release (if registered) |
| `keypressed(key)` | On key press (if registered) |
| `mousepressed(x, y, button)` | On mouse click |
| `leave()` | When switching away from this state |

The callbacks are wired automatically by `Gamestate.registerEvents()` in `main.lua`.
You only need to define the callbacks your state uses — the rest are ignored.

## Built-in states

```
[Splash] ──(3s)──→ [Menu] ──(New Game)──→ [Game] ──(Esc)──→ [Pause]
                       │                      ↑                    │
                   (Credits)                   └──(Esc)────────────┘
                       │
                       ↓
                  [Credits] ←──(Esc/click)─────┘
```

### Splash
- Shows Nova2D logo with animated particle stars and nebula effect
- Auto-transitions to Menu after 3 seconds
- Press any key to skip to Menu immediately
- Bootstraps hot reload on enter

### Menu
- Three options: New Game, Credits, Quit
- Navigate with Up/Down arrows or mouse click
- Enter/Space or click to select

### Game
- **Playable mini-platformer demo** — replace it with your own game code
- Wires Input, Jump, Collision, Health, Camera, Animation and the EntityManager
- Arrows/WASD to move, Space to jump, Escape to pause

### Pause
- Semi-transparent overlay (game continues updating underneath)
- Two options: Resume, Return to Menu
- Escape toggles pause on/off

### Credits
- Lists included libraries (hump, bump.lua, anim8, lurker, lovebird) and their authors
- Escape, Enter, Backspace, Space, or click returns to Menu

## Creating a new state

```lua
-- src/states/myState.lua
local Gamestate = require("hump.gamestate")
local Menu = require("src.states.menu")

local MyState = {}

function MyState:enter(previous, ...)
    -- Called when this state becomes active
    -- previous: the state we came from
    -- ...: any extra args passed to Gamestate.switch()
    self.timer = 0
end

function MyState:update(dt)
    self.timer = self.timer + dt
end

function MyState:draw()
    love.graphics.clear()
    love.graphics.printf("My State", 0, 280, 800, "center")
end

function MyState:keyreleased(key)
    if key == "escape" then
        Gamestate.switch(Menu)
    end
end

return MyState
```

## Wiring entities into a state

Entities use the constructor pattern: `Player.new(x, y)` returns an instance, and the
[EntityManager](../api/entity-manager.md) drives its lifecycle:

```lua
-- src/states/game.lua
local Gamestate = require("hump.gamestate")
local EntityManager = require("src.systems.entitymanager")
local Player = require("src.entities.player")

local Game = {}

function Game:enter()
    self.entities = EntityManager.new({ layers = { "actors" } })
    self.player = Player.new(400, 300)
    self.entities:add(self.player, "actors")
end

function Game:update(dt)
    self.entities:update(dt)
end

function Game:draw()
    love.graphics.clear()
    self.entities:draw()
end

function Game:keypressed(key)
    if key == "escape" then
        Gamestate.push(require("src.states.pause"))
    end
end

return Game
```

> The manager calls `enter(parent)` when the entity is added, `update(dt)` and `draw()`
> every frame, and `leave()` when it is removed. Without a manager you can call those
> methods yourself. See [Entities](entities.md) for details.

## State transitions

```lua
-- Switch to a state (replaces current)
Gamestate.switch(menu)

-- Switch and pass data to the next state's enter()
Gamestate.switch(game, score, level)

-- Push a state on top (for overlays like pause menus)
Gamestate.push(pause)

-- Pop back to the previous state
Gamestate.pop()
```

Use `push`/`pop` for overlays like pause menus. Use `switch` for normal navigation.

## Passing data between states

Since `enter(previous, ...)` receives the previous state and any extra arguments, you
can pass data naturally:

```lua
-- From game state, switch to results:
Gamestate.switch(require("src.states.results"), self.score)

-- In results state:
function Results:enter(previous, score)
    self.finalScore = score
end
```
