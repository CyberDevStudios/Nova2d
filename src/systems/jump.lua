-- Nova2D — Jump System
-- src/systems/jump.lua
-- Standalone module for platformer jump mechanics with coyote time,
-- jump buffer, variable height, and multi-jump support.

local jump = {}
jump.__index = jump

local DEFAULTS = {
    gravity       = 800,   -- pixels/s² positive = downward
    jumpVelocity  = -400,  -- pixels/s  negative = upward
    maxJumps      = 1,     -- total jumps allowed before landing
    coyoteTime    = 0.1,   -- seconds of grace after leaving ground
    bufferTime    = 0.1,   -- seconds to buffer a jump before landing
    variableHeight = true, -- cut velocity on release for short hops
}

--- Create a new jump instance.
-- @param config  Optional config table (shallow-merged over defaults)
-- @return jump instance
function jump.new(config)
    config = config or {}
    local self = setmetatable({}, jump)

    -- Merge config over defaults
    for k, v in pairs(DEFAULTS) do
        self[k] = (config[k] ~= nil) and config[k] or v
    end

    -- Writable properties — user sets each frame
    self.grounded         = false
    self.gravityMultiplier = 1.0

    -- Internal state
    self._velocityY     = 0
    self._jumpsUsed     = 0
    self._state         = "idle"     -- idle | charging | airborne
    self._wasGrounded   = false
    self._coyoteTimer   = 0
    self._bufferTimer   = -1         -- -1 = no buffered jump
    self._callbacks     = {}

    return self
end

--- Per-frame update.
-- Applies gravity, manages coyote / buffer timers, fires state events.
-- @param dt  Delta time in seconds
function jump:update(dt)
    if dt <= 0 then return end

    -- ── Grounded transitions ──────────────────────────────────────

    if not self.grounded and self._wasGrounded then
        -- Just left the ground
        self:_fire("leftGround")
        self._coyoteTimer = self.coyoteTime
        if self._state == "idle" then
            self._state = "airborne"
        end

    elseif self.grounded and not self._wasGrounded then
        -- Just landed
        self._jumpsUsed = 0
        self._state = "idle"
        self._velocityY = 0
        self:_fire("landed")

        -- Execute buffered jump if one was queued
        if self._bufferTimer > 0 then
            self._bufferTimer = -1
            self:_executeJump()
        end
    end

    -- ── Tick coyote timer ─────────────────────────────────────────

    if self._coyoteTimer > 0 then
        self._coyoteTimer = math.max(0, self._coyoteTimer - dt)
    end

    -- ── Tick buffer timer ─────────────────────────────────────────

    if self._bufferTimer > 0 then
        self._bufferTimer = self._bufferTimer - dt
        if self._bufferTimer <= 0 then
            self._bufferTimer = -1
            self:_fire("jumpBufferExpired")
        end
    end

    -- ── Apply gravity when airborne ───────────────────────────────

    if not self.grounded then
        self._velocityY = self._velocityY
                        + self.gravity * self.gravityMultiplier * dt

        -- Auto-transition charging → airborne when falling
        if self._state == "charging" and self._velocityY >= 0 then
            self._state = "airborne"
        end
    end

    self._wasGrounded = self.grounded
end

--- Attempt a jump.
-- Returns the applied Y velocity on success, nil otherwise.
-- Buffers the input if airborne and out of jumps.
-- @return number|nil
function jump:jump()
    if self.maxJumps <= 0 then
        return nil
    end

    if self._jumpsUsed >= self.maxJumps then
        -- Out of jumps — buffer the input if airborne
        if not self.grounded and self.bufferTime > 0 then
            self._bufferTimer = self.bufferTime
        end
        return nil
    end

    -- Determine whether we are in a position to jump
    local canJump = self.grounded
                or self._coyoteTimer > 0
                or (self._wasGrounded and not self.grounded)
                or self._jumpsUsed > 0

    if canJump then
        return self:_executeJump()
    end

    -- Not ground-able — buffer the input
    if self.bufferTime > 0 then
        self._bufferTimer = self.bufferTime
    end
    return nil
end

--- Internal jump execution (applies velocity, fires event).
-- @return number  The applied jump velocity
function jump:_executeJump()
    self._velocityY  = self.jumpVelocity
    self._jumpsUsed  = self._jumpsUsed + 1
    self._state      = "charging"
    self._coyoteTimer = 0
    self._bufferTimer = -1
    self:_fire("jumped", self._velocityY)
    return self._velocityY
end

--- Call on jump-key release.
-- Cuts upward velocity by 50% when variableHeight is enabled
-- and the instance is still ascending.
function jump:release()
    if self._state == "charging" and self.variableHeight and self._velocityY < 0 then
        self._velocityY = self._velocityY * 0.5
    end
    if self._state == "charging" then
        self._state = "airborne"
    end
end

--- Reset all state to initial values.
-- @return self  (for chaining)
function jump:reset()
    self._velocityY     = 0
    self._jumpsUsed     = 0
    self._state         = "idle"
    self._wasGrounded   = false
    self._coyoteTimer   = 0
    self._bufferTimer   = -1
    self.grounded       = false
    self.gravityMultiplier = 1.0
    return self
end

-- ── Events ─────────────────────────────────────────────────────────

--- Register an event listener.
-- Supported events: jumped(velocityY), landed(), leftGround(),
--                   jumpBufferExpired()
-- @param event  Event name string
-- @param cb     Callback function
-- @return function  The callback (for use with table.remove)
function jump:on(event, cb)
    if not self._callbacks[event] then
        self._callbacks[event] = {}
    end
    table.insert(self._callbacks[event], cb)
    return cb
end

function jump:_fire(event, ...)
    local cbs = self._callbacks[event]
    if cbs then
        for _, cb in ipairs(cbs) do
            cb(...)
        end
    end
end

-- ── Getters ─────────────────────────────────────────────────────────

--- Current Y velocity in pixels/s (positive = downward).
function jump:getVelocity()
    return self._velocityY
end

--- Whether the jump instance considers itself grounded
-- (mirrors the user-set .grounded property).
function jump:isGrounded()
    return self.grounded
end

--- Number of jumps used since last landing.
function jump:getJumpsUsed()
    return self._jumpsUsed
end

--- Remaining coyote time in seconds (0 = expired).
function jump:getCoyoteTimeRemaining()
    return math.max(0, self._coyoteTimer)
end

--- Remaining buffer time in seconds (0 = expired / none).
function jump:getBufferTimeRemaining()
    return math.max(0, self._bufferTimer)
end

return jump
