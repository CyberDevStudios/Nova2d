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
- **Placeholder state** — replace this with your game code
- By default shows a "Your game goes here" message
- Escape pushes the pause overlay

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
local Menu = require("states.menu")

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

Game objects (entities) are created in `enter()` and updated/drawn every frame. The
entity module acts as a blueprint — you create an instance table and pass it to the
entity's methods with colon syntax:

```lua
-- src/states/game.lua
local Gamestate = require("hump.gamestate")
local Player = require("entities.player")

local Game = {}

function Game:enter()
    -- Create an instance table and initialize it
    self.player = {}
    Player:enter(self.player)
end

function Game:update(dt)
    Player:update(self.player, dt)
end

function Game:draw()
    love.graphics.clear()
    Player:draw(self.player)
end

function Game:keyreleased(key)
    if key == "escape" then
        Gamestate.push(require("states.pause"))
    end
end

return Game
```

> The colon syntax `Player:enter(self.player)` is equivalent to
> `Player.enter(self.player)`. Inside `Player:enter()`, `self` refers to the instance
> table, not the `Player` module. See [Entities](entities.md) for details.

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
Gamestate.switch(require("states.results"), self.score)

-- In results state:
function Results:enter(previous, score)
    self.finalScore = score
end
```
