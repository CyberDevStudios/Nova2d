# Entity API

An entity is a Lua module that returns a **constructor**. Instances are created with
`.new(...)` and carry their own state; the module only provides the methods.

```lua
-- src/entities/player.lua
local Player = {}
Player.__index = Player

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x, self.y = x, y
    return self
end

function Player:update(dt)
    -- self is the instance, never the module
end

return Player
```

```lua
local Player = require("src.entities.player")
local player = Player.new(400, 300)
player:update(dt)
```

## Required method: `new(...)`

| Parameter | Type | Description |
|---|---|---|
| `...` | any | Whatever the entity needs (position, config, references) |

`new` must:

1. create a fresh table: `local self = setmetatable({}, Module)`
2. initialize instance state on `self`
3. return `self`

Anything the entity always needs should have a default so `Player.new()` works too.

## Lifecycle methods

These are called by the [EntityManager](../api/entity-manager.md) when the entity is
added to it. They are optional if you manage the entity by hand.

### `enter(parent)`

| Parameter | Type | Description |
|---|---|---|
| `parent` | EntityManager | The manager that now owns the entity |

```lua
function Enemy:enter(parent)
    self.parent = parent
end
```

### `update(dt)`

Per-frame logic. `dt` is delta time in seconds.

```lua
function Player:update(dt)
    self.x = self.x + self.speed * dt
end
```

**Rules**
- Always use `dt` for movement and timers
- No rendering here — `draw()` is the only place to draw
- Don't assume `update()` and `draw()` have the same frequency

### `draw()`

Rendering only. Reading state is fine; mutating it is not.

```lua
function Player:draw()
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end
```

### `leave()`

Cleanup when the entity is removed from the manager.

```lua
function Enemy:leave()
    self.parent = nil
end
```

## Optional: `tags`

The manager reads `entity.tags` (a list of strings) for `getByTag()`:

```lua
function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x, self.y = x, y
    self.tags = { "player" }
    return self
end
```

## Systems as entity fields

`EntityManager:attach(entity, name, system)` stores the system as `entity[name]` and
updates it before the entity:

```lua
entities:attach(player, "jump", Jump.new())
entities:attach(player, "health", Health.new({ maxHp = 100 }))

-- Player:update(dt)
if self.health:takeDamage(10) then
    self.animation:play()
end
```

## Complete example: patrolling enemy

```lua
-- src/entities/patrol_enemy.lua
local PatrolEnemy = {}
PatrolEnemy.__index = PatrolEnemy

function PatrolEnemy.new(x, y, range)
    local self = setmetatable({}, PatrolEnemy)
    self.x, self.y = x, y
    self.startX = x
    self.range = range or 100
    self.speed = 80
    self.dir = 1
    self.w, self.h = 30, 30
    self.tags = { "enemy" }
    return self
end

function PatrolEnemy:update(dt)
    self.x = self.x + self.speed * self.dir * dt
    if math.abs(self.x - self.startX) > self.range then
        self.dir = -self.dir
    end
end

function PatrolEnemy:draw()
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    love.graphics.setColor(1, 1, 1)
end

return PatrolEnemy
```

## Multi-instance

Every `new()` call returns an independent table:

```lua
function Game:enter()
    self.entities = EntityManager.new()
    for i = 1, 5 do
        self.entities:add(PatrolEnemy.new(100 * i, 300, 60))
    end
end
```

Each enemy owns its `x`, `y`, `dir`, `range` and `startX`; all of them share the module
functions through the metatable.
