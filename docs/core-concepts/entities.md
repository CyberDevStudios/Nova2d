# Entities

Entities are game objects — players, enemies, items, and anything else that lives in your
game world. In Nova2D an entity is a Lua module that returns a **constructor**, and every
object you create is an independent **instance** of it.

## The constructor pattern

Each entity module follows the same shape:

```lua
-- src/entities/player.lua
local Player = {}
Player.__index = Player

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.speed = 200
    return self
end

function Player:update(dt)
    self.x = self.x + self.speed * dt
end

function Player:draw()
    love.graphics.circle("fill", self.x, self.y, 16)
end

return Player
```

`Player.new(400, 300)` returns a new table whose metatable is the `Player` module. Method
lookups go to the module through `__index`, but **state lives on the instance** — the
module is never modified:

```lua
local p1 = Player.new(0, 0)
local p2 = Player.new(100, 0)

p1:update(1)
-- p1.x == 200, p2.x == 100, Player.x == nil
```

This is the same pattern used by the built-in systems (`Jump.new()`, `Health.new()`,
`Camera.new()`), so there is only one mental model for the whole framework.

## Entity lifecycle

Entities registered in an [EntityManager](../api/entity-manager.md) receive:

| Method | Purpose |
|---|---|
| `enter(parent)` | Called once when the entity is added. `parent` is the manager |
| `update(dt)` | Per-frame logic |
| `draw()` | Per-frame rendering |
| `leave()` | Cleanup when the entity is removed |

`enter` and `leave` are optional. If you use entities without a manager, you simply call
`entity:update(dt)` / `entity:draw()` yourself and skip the lifecycle hooks.

## Registering entities

```lua
local EntityManager = require("src.systems.entitymanager")
local Player = require("src.entities.player")

local entities = EntityManager.new({ layers = { "actors", "hazards" } })
local player = Player.new(64, 544)

entities:add(player, "actors")
entities:update(dt)   -- updates every entity in layer order
entities:draw()       -- draws every entity in layer order
```

The manager keeps update and draw order stable per layer, supports tags and queries, and
defers removals so you can call `remove()` from inside an update loop. See the
[EntityManager API](../api/entity-manager.md) for the full surface.

## Systems on entities

The manager can attach a system instance to an entity. Attached systems update **before**
the entity's own `update(dt)`, so the entity reads fresh system state in the same frame:

```lua
local Jump = require("src.systems.jump")

entities:attach(player, "jump", Jump.new({ jumpVelocity = -450 }))

-- inside Player:update(dt)
self.jump.grounded = self.world:check(self, self.x, self.y + 1)
if input:isPressed("jump") then self.jump:jump() end
self.y = self.y + self.jump:getVelocity() * dt
```

| System | Entity field | Typical use |
|---|---|---|
| `Jump` | `self.jump` | gravity, coyote time, jump buffering |
| `Health` | `self.health` | HP, damage, i-frames, death |
| `Animation` | `self.animation` | sprite frames |
| `Timer` | `self.timer` | cooldowns, durations |

## Conventions

- `PascalCase` for entity module names, one file per entity under `src/entities/`
- `local` everywhere; the module is returned at the end
- `update(dt)` for logic, `draw()` for rendering — never draw in `update`
- Keep state on the instance (`self`), never on the module
- Requires of project modules use the `src.` prefix: `require("src.entities.player")`

## Complete example: player + game state

```lua
-- src/entities/player.lua
local Player = {}
Player.__index = Player

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x, self.y = x, y
    self.speed = 200
    self.w, self.h = 16, 16
    return self
end

function Player:update(dt)
    if love.keyboard.isDown("left")  then self.x = self.x - self.speed * dt end
    if love.keyboard.isDown("right") then self.x = self.x + self.speed * dt end
end

function Player:draw()
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Player
```

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

> The playable demo in `src/states/game.lua` is a full version of this example: it wires
> Input, Jump, Collision, Health, Camera and Animation. The
> [platformer tutorial](../guides/tutorial-platformer.md) walks through it step by step.
