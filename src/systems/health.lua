-- Nova2D — Health System
-- src/systems/health.lua
-- Standalone module for HP tracking, damage, healing, invincibility
-- frames, and death state management.

local health = {}
health.__index = health

local DEFAULTS = {
    maxHp          = 100,   -- maximum hit points
    iFrameDuration = 1.0,   -- seconds of invincibility after damage
}

--- Create a new health instance.
-- @param config   Optional config table (shallow-merged over defaults)
-- @return health instance
function health.new(config)
    config = config or {}
    local self = setmetatable({}, health)

    -- Merge config over defaults
    for k, v in pairs(DEFAULTS) do
        self[k] = (config[k] ~= nil) and config[k] or v
    end

    -- Internal state
    self._currentHp         = self.maxHp
    self._state      = "alive"       -- alive | dead | invincible
    self._iFrameTimer = 0
    self._callbacks  = {}

    return self
end

--- Per-frame update.
-- Ticks the i-frame timer and fires iFramesEnd on transition.
-- @param dt  Delta time in seconds
function health:update(dt)
    if dt <= 0 then return end

    if self._state == "invincible" then
        self._iFrameTimer = self._iFrameTimer - dt
        if self._iFrameTimer <= 0 then
            self._iFrameTimer = 0
            self._state = "alive"
            self:_fire("iFramesEnd")
        end
    end
end

--- Apply damage to the entity.
-- @param amount  Amount of damage (positive number)
-- @param type    String tag for event listeners (e.g. "slash", "fall")
-- @return boolean  true if damage was applied, false if blocked
function health:takeDamage(amount, type)
    -- Dead entities cannot take damage
    if self._state == "dead" then
        return false
    end

    -- Invincible entities block damage entirely
    if self._state == "invincible" then
        return false
    end

    -- Clamp damage to at least 0
    amount = math.max(0, amount)
    if amount <= 0 then
        return false
    end

    -- Apply damage
    self._currentHp = math.max(0, self._currentHp - amount)
    type = type or "generic"

    -- Fire damaged event before state transitions
    -- so listeners see the state before it changes
    self:_fire("damaged", amount, type)

    -- Check for death
    if self._currentHp <= 0 then
        self._currentHp = 0
        self._state = "dead"
        self:_fire("died")
        return true
    end

    -- Enter invincibility
    if self.iFrameDuration > 0 then
        self._state = "invincible"
        self._iFrameTimer = self.iFrameDuration
        self:_fire("iFramesStart")
    end

    return true
end

--- Restore HP to the entity.
-- Clamped to maxHp. No-op when dead.
-- @param amount  Amount to heal (positive number)
-- @return boolean  true if healing was applied, false if blocked
function health:heal(amount)
    -- Dead entities cannot be healed
    if self._state == "dead" then
        return false
    end

    amount = math.max(0, amount)
    if amount <= 0 then
        return false
    end

    local before = self._currentHp
    self._currentHp = math.min(self.maxHp, self._currentHp + amount)
    local actual = self._currentHp - before

    if actual > 0 then
        self:_fire("healed", actual)
    end

    return actual > 0
end

--- Reset all state to initial values.
-- @return self  (for chaining)
function health:reset()
    self._currentHp         = self.maxHp
    self._state      = "alive"
    self._iFrameTimer = 0
    return self
end

-- ── Events ─────────────────────────────────────────────────────────

--- Register an event listener.
-- Supported events: damaged(amount, type), healed(amount), died(),
--                   iFramesStart(), iFramesEnd()
-- @param event  Event name string
-- @param cb     Callback function
-- @return function  The callback (for use with table.remove)
function health:on(event, cb)
    if not self._callbacks[event] then
        self._callbacks[event] = {}
    end
    table.insert(self._callbacks[event], cb)
    return cb
end

function health:_fire(event, ...)
    local cbs = self._callbacks[event]
    if cbs then
        for _, cb in ipairs(cbs) do
            cb(...)
        end
    end
end

-- ── Getters ─────────────────────────────────────────────────────────

--- Current HP value.
function health:getCurrentHp()
    return self._currentHp
end

--- Maximum HP value.
function health:getMaxHp()
    return self.maxHp
end

--- Set a new maximum HP value.
-- Re-clamps _currentHp if it exceeds the new max.
-- Does nothing if newMax is <= 0.
-- @param newMax  New maximum HP (must be > 0)
function health:setMaxHp(newMax)
    if newMax <= 0 then return end
    self.maxHp = newMax
    if self._currentHp > newMax then
        self._currentHp = newMax
    end
end

--- Whether the entity is dead (HP = 0, all operations locked).
function health:isDead()
    return self._state == "dead"
end

--- Whether the entity is currently invincible (i-frames active).
function health:isInvincible()
    return self._state == "invincible"
end

--- Remaining i-frame time in seconds (0 = not invincible).
function health:getIFramesRemaining()
    return math.max(0, self._iFrameTimer)
end

return health
