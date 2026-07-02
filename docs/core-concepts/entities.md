# Entities

Entities are game objects — players, enemies, items, and anything else that exists in your
game world. Each entity is a Lua module that acts as a **blueprint** (a collection of
methods), and you create **instances** as separate tables.

## How it works

In Lua, `obj:method(args)` is sugar for `obj.method(obj, args)`. An entity module defines
methods with `self`, and when you create an instance table and pass it with colon syntax,
`self` points to that instance:

```lua
local Player = {}

function Player:enter()
    -- self is the instance table, NOT the Player module
    self.x = 400
    self.y = 300
    self.speed = 200
end

-- In your state you create an instance and pass it:
local playerInstance = {}
Player:enter(playerInstance)
-- now playerInstance.x == 400, playerInstance.y == 300
```

The entity module (`Player`) is never modified. Each instance is its own table. This
means you can create multiple enemies from the same module:

```lua
local goblin1 = {}
local goblin2 = {}
Enemy:enter(goblin1, 100, 200)
Enemy:enter(goblin2, 300, 400)
-- Each goblin has its own x, y, hp
```

## Entity structure

```lua
-- src/entities/player.lua
local Player = {}

function Player:enter(parent, args)
    self.x = 400
    self.y = 300
    self.speed = 200
    self.hp = 100
end

function Player:update(dt)
    if love.keyboard.isDown("left") then
        self.x = self.x - self.speed * dt
    elseif love.keyboard.isDown("right") then
        self.x = self.x + self.speed * dt
    end
end

function Player:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", self.x, self.y, 20)
end

return Player
```

## Entity lifecycle

| Method | Purpose |
|---|---|
| `enter(parent, ...)` | Initialize entity state. `parent` is the owning state or manager |
| `update(dt)` | Per-frame logic |
| `draw()` | Per-frame rendering |
| `leave()` | Cleanup when removed |

### `enter(parent, ...)`

Called when the entity is created. `parent` is the table that owns this entity — usually
the state that created it (useful for accessing shared state or switching screens).

```lua
function Enemy:enter(parent, x, y)
    self.x = x
    self.y = y
    self.parent = parent  -- save reference to owning state
end

function Enemy:update(dt)
    -- Access the owning state through parent
    if self.x < 0 then
        self.parent:onEnemyOffscreen(self)
    end
end
```

## Conventions

- `PascalCase` for entity module names
- One file per entity under `src/entities/`
- Each file returns a table
- `local` everywhere, no globals
- `update(dt)` for logic, `draw()` for rendering
- `enter()` for initialization

## Complete example: player + game state

```lua
-- src/entities/player.lua
local Player = {}

function Player:enter()
    self.x = 400
    self.y = 300
    self.speed = 200
end

function Player:update(dt)
    if love.keyboard.isDown("left")  then self.x = self.x - self.speed * dt end
    if love.keyboard.isDown("right") then self.x = self.x + self.speed * dt end
    if love.keyboard.isDown("up")    then self.y = self.y - self.speed * dt end
    if love.keyboard.isDown("down")  then self.y = self.y + self.speed * dt end
end

function Player:draw()
    love.graphics.setColor(0.2, 0.6, 1)
    love.graphics.circle("fill", self.x, self.y, 25)
end

return Player
```

```lua
-- src/states/game.lua
local Gamestate = require("hump.gamestate")
local Player = require("entities.player")

local Game = {}

function Game:enter()
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

> **Note**: `Player:enter(self.player)` passes `self.player` (the empty instance table) as
> `self` inside the method. After `enter()`, `self.player` has `x`, `y`, and `speed` set
> on it. `Player` itself is unchanged.
