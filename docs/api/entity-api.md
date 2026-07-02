# Entity API

An entity is a **Lua module that acts as a blueprint** for a game object.
The module defines methods using `self`, and each instance is a separate table passed
with colon syntax.

```lua
-- The module is the blueprint
local Player = {}

function Player:enter()
    -- self points to the instance, not the module
    self.x = 400
end

return Player

-- In the state:
local instance = {}
Player:enter(instance)
-- instance.x == 400
```

## Lifecycle Methods

### `enter(parent, ...)`
**Purpose**: initialize the entity's state.

| Parameter | Type | Description |
|---|---|---|
| `parent` | table (optional) | The state or manager that created this entity |
| `...` | any | Additional arguments |

`parent` is useful so the entity can communicate with the state that created it (e.g.
notify when the ball goes off-screen, or access other entities).

```lua
function Enemy:enter(parent, x, y)
    self.x = x
    self.y = y
    self.hp = 100
    self.speed = 150
    self.parent = parent  -- store reference to the state
end

function Enemy:update(dt)
    self.x = self.x - self.speed * dt
    -- If off-screen, notify the state
    if self.x < -50 and self.parent then
        self.parent:onEnemyOffscreen(self)
    end
end
```

**Without parent** (simple usage):
```lua
function Player:enter()
    self.x = 400
    self.y = 300
    self.speed = 200
end

-- In the state:
self.player = {}
Player:enter(self.player)
```

---

### `update(dt)`
**Purpose**: per-frame logic. Movement, input, collisions, etc.

| Parameter | Type | Description |
|---|---|---|
| `dt` | number | Delta time in seconds (always frame-independent) |

```lua
function Player:update(dt)
    if love.keyboard.isDown("left") then
        self.x = self.x - self.speed * dt
    end
end
```

**Rules**:
- Always use `dt` for movement and timers
- No rendering — `draw()` is the only place to draw
- Don't assume `update()` and `draw()` have the same frequency

---

### `draw()`
**Purpose**: render the entity. Only draw, don't modify state.

```lua
function Player:draw()
    love.graphics.setColor(0.2, 0.6, 1)
    love.graphics.circle("fill", self.x, self.y, 25)
end
```

---

### `leave()`
**Purpose**: clean up resources when the entity is destroyed.

```lua
function Enemy:leave()
    self.timer = nil
    self.parent = nil
end
```

## Conventions

| Rule | Reason |
|---|---|
| `PascalCase` for the module | Differentiates entities from utils/helpers |
| `local` always | No globals. The module is returned at the end |
| `update(dt)` separated from `draw()` | Consistency with Love2D and hot reload |
| State in `self`, not in the module | Each instance has its own data |
| `enter()` for init, not the module | Compatible with hot reload |

## Complete example: patrolling enemy

```lua
-- src/entities/patrol_enemy.lua
local PatrolEnemy = {}

function PatrolEnemy:enter(parent, x, y, range)
    self.x = x
    self.y = y
    self.startX = x
    self.range = range or 100
    self.speed = 80
    self.dir = 1
end

function PatrolEnemy:update(dt)
    self.x = self.x + self.speed * self.dir * dt

    -- Change direction when reaching the boundary
    if math.abs(self.x - self.startX) > self.range then
        self.dir = -self.dir
    end
end

function PatrolEnemy:draw()
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.rectangle("fill", self.x, self.y, 30, 30)
end

return PatrolEnemy
```

## Multi-instance

Creating multiple instances of the same module is straightforward — each one is a separate
table:

```lua
-- In the state
function Game:enter()
    self.enemies = {}
    for i = 1, 5 do
        self.enemies[i] = {}
        PatrolEnemy:enter(self.enemies[i], self, 100 * i, 300, 60)
    end
end

function Game:update(dt)
    for _, e in ipairs(self.enemies) do
        PatrolEnemy:update(e, dt)
    end
end

function Game:draw()
    for _, e in ipairs(self.enemies) do
        PatrolEnemy:draw(e)
    end
end
```

Each enemy has its own `x`, `y`, `dir`, `range` and `startX`. They all share the
`PatrolEnemy` module functions.
