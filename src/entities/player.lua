-- Nova2D — Player entity (mini-platformer demo)
-- src/entities/player.lua
-- The playable character. Follows the metatable constructor pattern:
-- Player.new(x, y) returns an instance whose methods come from this
-- module without ever modifying it (see docs/core-concepts/entities.md).
--
-- The state owns the shared systems (Input, Collision world) and injects
-- them; the Jump, Health and Animation systems are attached by the
-- EntityManager and reachable as self.jump / self.health / self.animation.

local Player = {}
Player.__index = Player

local SPEED        = 180   -- horizontal speed, pixels/s
local RESPAWN_COST = 20    -- HP lost when falling into a pit
local PIT_Y        = 700   -- fall below this to respawn

--- Create a player instance.
-- @param x, y  Spawn position (top-left of the 16x16 hitbox)
-- @return Player instance
function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x, self.y = x, y
    self.spawnX, self.spawnY = x, y
    self.w, self.h = 16, 16
    self.speed = SPEED
    self.tags = { "player" }
    return self
end

--- Called by the EntityManager when the player is registered.
-- @param parent  The EntityManager that owns this instance
function Player:enter(parent)
    self.parent = parent
end

--- Teleport back to the spawn point and reset the attached systems.
-- @param fullReset  Also restore HP (used on death)
function Player:respawn(fullReset)
    self.x, self.y = self.spawnX, self.spawnY
    self.jump:reset()
    if fullReset then
        self.health:reset()
    end
    self.world:update(self)      -- teleport the collision box, no events
end

--- Per-frame logic: input, movement, jump, pit check.
function Player:update(dt)
    local input, jump, world = self.input, self.jump, self.world

    -- Horizontal movement from the Input System actions
    local vx = 0
    if input:isPressed("left") then vx = vx - self.speed end
    if input:isPressed("right") then vx = vx + self.speed end

    -- Walk cycle runs while moving, freezes while idle
    if vx ~= 0 then
        self.animation:resume()
    else
        self.animation:pause()
    end

    -- Jump: the attached Jump system handles coyote time, buffering and
    -- variable height. `grounded` is set by the state before the
    -- EntityManager updates (see src/states/game.lua).
    if input:isPressed("jump") then jump:jump() end
    if input:isReleased("jump") then jump:release() end

    -- Move through the collision world (resolves and writes back x/y)
    world:move(self, self.x + vx * dt, self.y + jump:getVelocity() * dt)

    -- Pit: fell out of the level → respawn with a damage penalty
    if self.y > PIT_Y then
        self:respawn(false)
        self.health:takeDamage(RESPAWN_COST, "fall")
    end
end

--- Render the animated sprite. Blinks while i-frames are active.
function Player:draw()
    local alpha = 1
    if self.health:isInvincible() and math.floor(love.timer.getTime() * 20) % 2 == 0 then
        alpha = 0.35
    end
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(self.sheet, self.animation:getQuad(), self.x, self.y)
    love.graphics.setColor(1, 1, 1)
end

return Player
