-- Nova2D — Timer System
-- src/systems/timer.lua
-- Standalone module for countdown and stopwatch timing with
-- pause/resume, tick events, and expiration detection.

local timer = {}
timer.__index = timer

local DEFAULTS = {
    mode     = "countdown",   -- "countdown" | "stopwatch"
    duration = 1,             -- seconds
}

--- Create a new timer instance.
-- @param config  Optional config table (shallow-merged over defaults)
-- @return timer instance
function timer.new(config)
    config = config or {}
    local self = setmetatable({}, timer)

    -- Merge config over defaults
    for k, v in pairs(DEFAULTS) do
        self[k] = (config[k] ~= nil) and config[k] or v
    end

    -- Internal state
    self._elapsed  = 0
    self._paused   = false
    self._expired  = false
    self._callbacks = {}

    return self
end

--- Per-frame update.
-- Advances the timer by dt seconds. Fires tick each frame and
-- expired when a countdown reaches zero.
-- @param dt  Delta time in seconds
function timer:update(dt)
    if dt <= 0 then return end
    if self._paused then return end
    if self._expired then return end

    self._elapsed = self._elapsed + dt

    -- Fire tick with context-appropriate values
    self:_fire("tick", self:getElapsed(), self:getRemaining())

    -- Check expiration (countdown only)
    if self.mode == "countdown" and self._elapsed >= self.duration then
        self._elapsed = self.duration  -- clamp
        self._expired = true
        self:_fire("expired")
    end
end

--- Pause the timer.
-- Stops advancing time on subsequent update() calls.
function timer:pause()
    self._paused = true
end

--- Resume the timer.
-- If the timer was expired, restarts from full duration.
-- No-op when the timer is already running.
function timer:resume()
    -- Expired → restart from full duration
    if self._expired then
        self:reset()
        return
    end

    -- No-op if already running
    if not self._paused then return end

    self._paused = false
end

--- Reset to initial state.
-- Elapsed → 0, expired → false, paused → false.
-- @return self  (for chaining)
function timer:reset()
    self._elapsed = 0
    self._expired = false
    self._paused  = false
    return self
end

-- ── Events ─────────────────────────────────────────────────────────

--- Register an event listener.
-- Supported events: tick(elapsed, remaining), expired()
-- @param event  Event name string
-- @param cb     Callback function
-- @return function  The callback (for use with table.remove)
function timer:on(event, cb)
    if not self._callbacks[event] then
        self._callbacks[event] = {}
    end
    table.insert(self._callbacks[event], cb)
    return cb
end

function timer:_fire(event, ...)
    local cbs = self._callbacks[event]
    if cbs then
        for _, cb in ipairs(cbs) do
            cb(...)
        end
    end
end

-- ── Getters ─────────────────────────────────────────────────────────

--- Time elapsed since start (or last reset) in seconds.
function timer:getElapsed()
    return self._elapsed
end

--- Time remaining in seconds (countdown mode only).
-- @return number|nil  Remaining seconds, or nil in stopwatch mode
function timer:getRemaining()
    if self.mode == "countdown" then
        return math.max(0, self.duration - self._elapsed)
    end
    return nil
end

--- Progress toward completion as a 0–1 value (countdown mode only).
-- @return number|nil  0 at start, 1 when expired, or nil in stopwatch mode
function timer:getProgress()
    if self.mode ~= "countdown" then
        return nil
    end
    if self.duration <= 0 then
        return self._expired and 1 or 0
    end
    return math.min(1, self._elapsed / self.duration)
end

--- Whether the timer is actively running (not paused, not expired).
function timer:isRunning()
    return not self._paused and not self._expired
end

--- Whether the timer has expired (countdown reached zero).
-- Always false in stopwatch mode.
function timer:isExpired()
    if self.mode == "countdown" then
        return self._expired
    end
    return false
end

return timer
