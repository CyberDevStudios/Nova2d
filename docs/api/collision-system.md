# Collision System

AABB collision for games: a **spatial-hash world** with move/check/query, plus **pure geometry helpers** for one-off tests. Built on top of `bump.lua` (already bundled with Nova2D).

```lua
local collision = require("src.systems.collision")

local world = collision.new({ cellSize = 64 })
```

## Quick start

```lua
local collision = require("src.systems.collision")

local world = collision.new()

local player = { x = 0, y = 0, w = 16, h = 16 }
local wall   = { x = 100, y = 0, w = 32, h = 96 }

world:add(player)
world:add(wall)

world:on("collision", function(entity, other, col)
    print(entity, "hit", other)     -- col.normal / col.touch available for custom resolution
end)

function love.update(dt)
    local speed = 120
    local x, y, collided = world:move(player, player.x + speed * dt, player.y)
    -- player.x/y are updated automatically; `collided` tells you something was hit
end
```

## Config

### `collision.new(config)`

All fields are optional.

| Field | Type | Default | Description |
|---|---|---|---|
| `cellSize` | number | `64` | Spatial-hash cell size in pixels. Smaller cells = faster queries for sparse worlds; keep it near your average entity size |

## Geometry helpers

Pure functions on the module — no world needed.

### `collision.box(x, y, w, h)`

Returns an AABB `{ x = x, y = y, w = w, h = h }`.

### `collision.overlaps(a, b)`

Returns `true` when two boxes overlap (inclusive edges).

```lua
local bullet = collision.box(bx, by, 4, 4)
local target = collision.box(tx, ty, 32, 32)
if collision.overlaps(bullet, target) then
    -- hit!
end
```

### `collision.contains(box, px, py)`

Returns `true` when the point `(px, py)` is inside the box.

## World API

### `world:add(entity)`

Registers an entity in the world.

- Reads the collision box from `entity.collider` (`{ x, y, w, h }`) if present, otherwise from `entity.x, entity.y, entity.w, entity.h`
- The entity table itself is the identity key — pass the same table to every call
- Returns the entity

```lua
-- Option A: plain fields
local player = { x = 0, y = 0, w = 16, h = 16 }

-- Option B: dedicated collider box (entity.x/y can differ from the hitbox)
local boss = { x = 50, y = 50, collider = { x = 54, y = 54, w = 40, h = 40 } }
```

### `world:remove(entity)`

Removes the entity from the world.

### `world:update(entity)`

Repositions the entity's collision box from its current fields — a **teleport** with no collision response and no events. Use after directly changing `entity.x/y`.

### `world:move(entity, goalX, goalY, filter)`

Moves the entity toward the goal, resolving collisions along the way.

- Fires `collision(entity, other, col)` for every contact
- Writes the resolved position back to `entity.collider.x/y` (or `entity.x/y`)
- Returns `actualX, actualY, collided` — `collided` is `true` when any contact happened
- `filter` is an optional bump filter function: `function(item, other) return "slide" | "cross" | "touch" | "bounce" | nil end` (`nil` = ignore that pair)

### `world:check(entity, goalX, goalY, filter)`

Checks whether moving would collide — no movement, no events. Returns `true` when colliding.

```lua
-- Only jump if there is ground below
if world:check(player, player.x, player.y + 1) then
    player:jump()
end
```

### `world:query(x, y, w, h, filter)`

Returns the list of entities overlapping the given rectangle.

### `world:queryPoint(x, y)`

Returns the list of entities under a point.

```lua
local hovered = world:queryPoint(love.mouse.getPosition())
for _, entity in ipairs(hovered) do
    -- click target
end
```

### `world:reset()`

Removes every entity from the world. Returns `self`.

## Events

Register listeners with `world:on(event, callback)`.

| Event | Arguments | Fires |
|---|---|---|
| `collision` | `entity, other, col` | For every contact during `world:move()`. `col.normal` and `col.touch` are available for custom resolution |

## Notes

- The module wraps `bump.lua` (kikito/bump.lua v3.1.7), installed automatically by `love gestor/ install`
- Default movement response is **slide** (entities slide along obstacles instead of stopping)
- Position write-back keeps `entity.collider` in sync automatically; for plain-field entities, `entity.x/y` are updated
- Enter/exit pair detection is planned for a future release — track hits yourself via the `collision` event for now