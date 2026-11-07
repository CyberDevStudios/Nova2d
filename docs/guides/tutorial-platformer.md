# Tutorial: Platformer Demo

The `Game` state that ships with Nova2D is a small playable platformer. It is the
reference wiring for the framework: Input, Jump, Collision, Health, Camera, Animation and
the EntityManager working together. This guide explains how it is built so you can adapt
it or replace it.

Run `love .`, choose **New Game** and try it:

- Arrows / WASD to move
- Space to jump (variable height — release early for a shorter jump)
- Spikes deal damage and grant brief i-frames
- Falling into the pit respawns you with an HP penalty
- Escape pauses

Files involved:

```
src/states/game.lua        -- level, state orchestration, HUD
src/entities/player.lua    -- player entity + systems
src/entities/hazard.lua    -- spike strip entity
assets/images/player.png   -- 4-frame 16x16 sprite sheet
```

## 1. The level

The level is plain data: solid rectangles for the collision world and spike strips for
the entities. Static geometry does not need an entity — the state draws it directly.

```lua
local SOLIDS = {
    { 0,    560, 560, 40 },    -- floor, left of the pit
    { 720,  560, 880, 40 },    -- floor, right of the pit
    { 0,    0,   12,  600 },   -- left wall
    { 1588, 0,   12,  600 },   -- right wall
    { 240,  470, 160, 16 },    -- platform A
    -- ...
}

local HAZARDS = {
    { x = 400,  y = 548, w = 32 },
    { x = 1100, y = 548, w = 48 },
    { x = 980,  y = 448, w = 32 },
}
```

In `State:enter()` the solids are registered in the collision world:

```lua
self.world = Collision.new({ cellSize = 64 })
for _, s in ipairs(SOLIDS) do
    self.world:add({ x = s[1], y = s[2], w = s[3], h = s[4] })
end
```

## 2. The player entity

`src/entities/player.lua` follows the constructor pattern
([Entities](../core-concepts/entities.md)):

```lua
local Player = {}
Player.__index = Player

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x, self.y = x, y
    self.spawnX, self.spawnY = x, y
    self.w, self.h = 16, 16
    self.speed = 180
    self.tags = { "player" }
    return self
end

function Player:enter(parent)
    self.parent = parent
end
```

The state injects the shared systems (`input`, `world`) and attaches the per-entity
systems through the manager:

```lua
local player = Player.new(SPAWN_X, SPAWN_Y)
player.input = self.input
player.world = self.world
player.sheet = love.graphics.newImage("assets/images/player.png")

self.entities:attach(player, "jump", Jump.new({ jumpVelocity = -450 }))
self.entities:attach(player, "health", Health.new({ maxHp = 100, iFrameDuration = 1 }))
self.entities:attach(player, "animation", Animation.new({
    image = player.sheet,
    frameWidth = 16,
    frameHeight = 16,
    frames = { 1, 2, 3, 4 },
    fps = 8,
    loop = true,
}))

self.entities:add(player, "actors")
self.world:add(player)
```

Because `attach` stores each system as `entity.<name>`, the entity reads `self.jump`,
`self.health` and `self.animation` directly.

## 3. Update order (the important part)

The manager updates attached systems **before** `entity:update(dt)`. That makes the
ground probe a state responsibility: it must run before `entities:update(dt)` so the Jump
system sees the current `grounded` value in the same frame.

```lua
function State:update(dt)
    self.input:update(dt)

    local player = self.player
    player.jump.grounded = self.world:check(player, player.x, player.y + 1)

    self.entities:update(dt)
    self.camera:update(dt)
end
```

Inside `Player:update(dt)` the flow is:

1. read horizontal input
2. start/pause the walk animation
3. `jump()` on press, `release()` on release (variable height)
4. move through the collision world with the Jump velocity
5. respawn if the player fell below the level

```lua
function Player:update(dt)
    local input, jump, world = self.input, self.jump, self.world

    local vx = 0
    if input:isPressed("left") then vx = vx - self.speed end
    if input:isPressed("right") then vx = vx + self.speed end

    if vx ~= 0 then self.animation:resume() else self.animation:pause() end

    if input:isPressed("jump") then jump:jump() end
    if input:isReleased("jump") then jump:release() end

    world:move(self, self.x + vx * dt, self.y + jump:getVelocity() * dt)

    if self.y > PIT_Y then
        self:respawn(false)
        self.health:takeDamage(RESPAWN_COST, "fall")
    end
end
```

`world:move` resolves collisions and writes the corrected position back to the entity, so
assigning the result is unnecessary.

## 4. Hazards and damage

`Hazard.new(x, y, w)` creates a spike strip with `tags = { "hazard" }`. It is added to
both the manager (to draw) and the collision world (to be solid). Contact damage comes
from the collision event, not from polling:

```lua
self.world:on("collision", function(entity, other)
    if entity ~= player or not other.tags then return end
    for _, tag in ipairs(other.tags) do
        if tag == "hazard" then
            if player.health:takeDamage(other.damage, "spike") then
                self.camera:startShake(6, 0.25)
            end
            return
        end
    end
end)
```

`takeDamage` returns `false` while i-frames are active, so holding against a spike does
not drain HP every frame.

Death is handled once, through the Health system's event:

```lua
player.health:on("died", function()
    player:respawn(true)
    self.camera:startShake(10, 0.4)
end)
```

The callback runs after Health sets its state to `dead`, so `health:reset()` inside
`respawn()` leaves the player alive with full HP.

## 5. Rendering

The state draws the level, the entities through the manager, and the HUD without the
camera transform:

```lua
function State:draw()
    love.graphics.clear(0.055, 0.055, 0.075)

    self.camera:attach()
    self:drawLevel()
    self.entities:draw()
    self.camera:detach()

    self:drawHud()
end
```

The player sprite blinks during i-frames using `health:isInvincible()`:

```lua
function Player:draw()
    local alpha = 1
    if self.health:isInvincible()
        and math.floor(love.timer.getTime() * 20) % 2 == 0 then
        alpha = 0.35
    end
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(self.sheet, self.animation:getQuad(), self.x, self.y)
    love.graphics.setColor(1, 1, 1)
end
```

## 6. Pause

The game pushes the pause overlay and does not pause the game loop, matching the built-in
`Pause` state:

```lua
function State:keypressed(key)
    if key == "escape" then
        Gamestate.push(Pause)
    end
end
```

## Next steps

- [EntityManager](../api/entity-manager.md) — full registry API
- [Collision System](../api/collision-system.md) — `move`, `check`, `query`
- [Jump System](../api/jump-system.md) — coyote time and buffering
- [Health System](../api/health-system.md) — i-frames and death
