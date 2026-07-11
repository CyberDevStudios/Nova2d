-- Nova2D — Camera System
-- src/systems/camera.lua
-- Standalone module for target-following camera with smooth lerp,
-- screen shake, zoom clamping, and view bounds.
-- Uses only love.graphics transform APIs — zero external dependencies.

local camera = {}
camera.__index = camera

local DEFAULTS = {
    smoothing = 0.1,   -- lerp factor (0–1, lower = smoother)
    zoom      = 1,      -- initial zoom level
    minZoom   = 0.25,   -- minimum zoom (clamp floor)
    maxZoom   = 4,      -- maximum zoom (clamp ceiling)
    bounds    = nil,    -- {x, y, w, h} or nil for unbounded
}

--- Create a new camera instance.
-- @param config  Optional config table (shallow-merged over defaults)
-- @return camera instance
function camera.new(config)
    config = config or {}
    local self = setmetatable({}, camera)

    -- Merge config over defaults
    for k, v in pairs(DEFAULTS) do
        self[k] = (config[k] ~= nil) and config[k] or v
    end

    -- Internal state
    self._x              = 0
    self._y              = 0
    self._zoom           = self.zoom
    self._target         = nil
    self._shaking        = false
    self._shakeIntensity = 0
    self._shakeDuration  = 0
    self._shakeTimer     = 0
    self._callbacks      = {}

    return self
end

--- Per-frame update.
-- Lerps toward the target, decays shake, and clamps to bounds.
-- @param dt  Delta time in seconds
function camera:update(dt)
    if dt <= 0 then return end

    -- ── Lerp toward target ─────────────────────────────────────────
    if self._target then
        local lerp = 1 - (1 - self.smoothing) ^ (dt * 60)
        self._x = self._x + (self._target.x - self._x) * lerp
        self._y = self._y + (self._target.y - self._y) * lerp
    end

    -- ── Shake decay ────────────────────────────────────────────────
    if self._shaking then
        self._shakeTimer = self._shakeTimer - dt
        if self._shakeTimer <= 0 then
            self._shakeTimer = 0
            self._shaking = false
            self:_fire("shakeEnd")
        end
    end

    -- ── Clamp to bounds ────────────────────────────────────────────
    if self.bounds then
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
        local halfW = w / (2 * self._zoom)
        local halfH = h / (2 * self._zoom)
        local left   = self.bounds[1] + halfW
        local right  = self.bounds[1] + self.bounds[3] - halfW
        local top    = self.bounds[2] + halfH
        local bottom = self.bounds[2] + self.bounds[4] - halfH

        if left < right then
            self._x = math.max(left, math.min(self._x, right))
        else
            self._x = (left + right) / 2
        end

        if top < bottom then
            self._y = math.max(top, math.min(self._y, bottom))
        else
            self._y = (top + bottom) / 2
        end
    end
end

--- Set the camera to follow a target.
-- The target must have `.x` and `.y` fields.
-- Calling with nil or without arguments stops following.
-- @param target  Table with .x and .y (or nil)
function camera:follow(target)
    self._target = target
    if target then
        self._x = target.x
        self._y = target.y
    end
end

--- Apply camera transforms. Call before drawing the game world.
-- Pushes the transform stack, applies translate + scale with
-- optional shake offset. Must be paired with :detach() after drawing.
function camera:attach()
    love.graphics.push()

    local sx, sy = 0, 0
    if self._shaking and self._shakeDuration > 0 then
        local current = self._shakeIntensity * (self._shakeTimer / self._shakeDuration)
        sx = (love.math.random() * 2 - 1) * current
        sy = (love.math.random() * 2 - 1) * current
    end

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    love.graphics.translate(w / 2 + sx, h / 2 + sy)
    love.graphics.scale(self._zoom)
    love.graphics.translate(-self._x, -self._y)
end

--- Restore the transform stack.
-- Call after drawing the game world, before drawing HUD/UI.
function camera:detach()
    love.graphics.pop()
end

--- Start a screen shake effect.
-- The shake offset is applied in screen-space pixels. Intensity
-- decays linearly to zero over the given duration.
-- @param intensity  Maximum pixel offset
-- @param duration   Duration in seconds
function camera:startShake(intensity, duration)
    self._shaking = true
    self._shakeIntensity = intensity
    self._shakeDuration  = duration
    self._shakeTimer     = duration
    self:_fire("shakeStart", intensity, duration)
end

--- Set the zoom level, clamped to [minZoom, maxZoom].
-- @param zoom  New zoom value
function camera:setZoom(zoom)
    self._zoom = math.max(self.minZoom, math.min(zoom, self.maxZoom))
end

--- Set viewport bounds for camera clamping.
-- The camera position will be constrained so the viewport
-- stays within these boundaries.
-- @param x  Left edge in world coordinates
-- @param y  Top edge in world coordinates
-- @param w  Width of the bounded area
-- @param h  Height of the bounded area
function camera:setBounds(x, y, w, h)
    self.bounds = {x, y, w, h}
end

--- Remove viewport bounds (camera can move freely).
function camera:clearBounds()
    self.bounds = nil
end

--- Reset all runtime state to initial values.
-- Config fields (smoothing, minZoom, maxZoom, bounds) are preserved.
-- @return self  (for chaining)
function camera:reset()
    self._x              = 0
    self._y              = 0
    self._zoom           = self.zoom
    self._target         = nil
    self._shaking        = false
    self._shakeIntensity = 0
    self._shakeDuration  = 0
    self._shakeTimer     = 0
    return self
end

-- ── Events ─────────────────────────────────────────────────────────

--- Register an event listener.
-- Supported events: shakeStart(intensity, duration), shakeEnd()
-- @param event  Event name string
-- @param cb     Callback function
-- @return function  The callback (for use with table.remove)
function camera:on(event, cb)
    if not self._callbacks[event] then
        self._callbacks[event] = {}
    end
    table.insert(self._callbacks[event], cb)
    return cb
end

function camera:_fire(event, ...)
    local cbs = self._callbacks[event]
    if cbs then
        for _, cb in ipairs(cbs) do
            cb(...)
        end
    end
end

-- ── Getters ─────────────────────────────────────────────────────────

--- Current camera position in world coordinates.
-- @return x, y  Camera center position
function camera:getPosition()
    return self._x, self._y
end

--- Current zoom level (clamped to [minZoom, maxZoom]).
-- @return number
function camera:getZoom()
    return self._zoom
end

--- Whether the camera is currently shaking.
-- @return boolean
function camera:isShaking()
    return self._shaking
end

--- The visible world rectangle, in world coordinates.
-- Returns the top-left corner and dimensions of the area
-- visible through the current camera transform.
-- @return x, y, w, h  Left, top, width, height in world units
function camera:getViewRect()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local vw = w / self._zoom
    local vh = h / self._zoom
    return self._x - vw / 2, self._y - vh / 2, vw, vh
end

return camera
