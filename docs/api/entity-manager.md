# EntityManager API

`src/systems/entitymanager.lua` — central registry for game entities. It drives the
`enter` / `update` / `draw` / `leave` lifecycle, keeps z-order through layers, supports
tags and queries, and makes removal safe inside update loops.

```lua
local EntityManager = require("src.systems.entitymanager")

local entities = EntityManager.new({ layers = { "background", "actors", "effects" } })
```

## Constructor

### `EntityManager.new(config)`

| Option | Type | Default | Description |
|---|---|---|---|
| `layers` | table | `{ "default" }` | Layer names, back to front. The first is the default |

```lua
local entities = EntityManager.new({ layers = { "floor", "actors", "hud" } })
```

## Registry

### `entities:add(entity, layer)`

Registers an entity, calls `entity:enter(manager)` and fires `"added"`. Returns the entity.

- `layer` defaults to `entity.layer`, then to the first configured layer.
- Adding the same entity twice raises an error.
- Adding an entity that was scheduled for removal **cancels** the removal.
- An unknown layer raises an error.

```lua
entities:add(player, "actors")
```

### `entities:remove(entity)`

Schedules a removal and returns `true` when the entity was registered. The entity keeps
its place until the end of the current `update()` (or the start of the next one when
called between frames). At that point `entity:leave()` runs and `"removed"` fires.

```lua
function Bullet:update(dt)
    if self.x > 900 then
        self.parent:remove(self)   -- safe inside update
    end
end
```

### `entities:clear()` / `entities:reset()`

Removes every entity immediately: `leave()` and `"removed"` fire for each, and the
registry is emptied. `reset()` is an alias.

### `entities:setLayer(entity, layer)`

Moves an entity to another layer, changing its update/draw position. An unknown layer
raises an error. If the entity is not registered, it only stores the layer for the next
`add()`.

## Composition

### `entities:attach(entity, name, system)`

Stores the system as `entity[name]` and updates it automatically **before** the entity's
own `update(dt)`. Returns the system.

```lua
entities:attach(player, "jump", Jump.new({ jumpVelocity = -450 }))
entities:attach(player, "health", Health.new({ maxHp = 100 }))
-- Player:update reads self.jump and self.health
```

Pick names that don't collide with the entity's own fields or methods.

### `entities:detach(entity, name)`

Removes `entity[name]` and stops updating it. Returns the detached system, or `nil`.

## Queries

### `entities:getByTag(tag)`

Returns every entity whose `tags` array contains `tag`, in layer order.

```lua
for _, enemy in ipairs(entities:getByTag("enemy")) do
    enemy:alert()
end
```

### `entities:query(fn)`

Returns every entity for which `fn(entity)` is truthy, in layer order.

```lua
local hurt = entities:query(function(e) return e.health and e.health:getCurrentHp() < 20 end)
```

## Lifecycle

### `entities:update(dt)`

For every entity, in layer order:

1. updates attached systems, in attachment order
2. calls `entity:update(dt)`

Pending removals are applied before the loop and again when it ends. Entities added
during the loop start updating on the next frame. A non-positive `dt` skips updates but
still applies pending removals.

### `entities:draw()`

Calls `entity:draw()` for every entity, in layer order (back to front). Entities pending
removal are skipped. `draw()` never mutates the registry.

## Events

### `entities:on(event, cb)`

| Event | Arguments | When |
|---|---|---|
| `"added"` | `entity` | After `enter()` and registration |
| `"removed"` | `entity` | After `leave()` during a flush |

Returns the callback so it can be stored and removed later.

```lua
entities:on("removed", function(entity)
    if entity.tags and entity.tags[1] == "enemy" then
        score = score + 10
    end
end)
```

## Complete example

```lua
local EntityManager = require("src.systems.entitymanager")
local Player = require("src.entities.player")
local Hazard = require("src.entities.hazard")
local Jump = require("src.systems.jump")

local entities = EntityManager.new({ layers = { "actors", "hazards" } })

local player = Player.new(64, 544)
entities:attach(player, "jump", Jump.new())
entities:add(player, "actors")

entities:add(Hazard.new(400, 548, 32), "hazards")

function love.update(dt)
    player.jump.grounded = world:check(player, player.x, player.y + 1)
    entities:update(dt)
end

function love.draw()
    entities:draw()
end
```

See also: [Entity API](entity-api.md), [Entities](../core-concepts/entities.md).
