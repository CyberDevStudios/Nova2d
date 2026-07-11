-- Nova2D — Input System
-- src/systems/input.lua
-- Standalone action-based input system with binding remapping
-- and buffer support. Supports keyboard and gamepad.

local input = {}
input.__index = input

local DEFAULTS = {
    bufferWindow = 0,
    defaultBindings = {
        jump   = "space",
        left   = "left",
        right  = "right",
        up     = "up",
        down   = "down",
        action = "x",
        cancel = "z",
        start  = "return",
    },
}

-- Module-level Love2D hook management.
-- Installs love.keypressed / love.keyreleased once and
-- dispatches to all active input instances.
local _hooked    = false
local _oldKeypressed  = nil
local _oldKeyreleased = nil
local _instances = {}

--- Create a new input instance.
-- Internally hooks love.keypressed and love.keyreleased for
-- buffer timestamp capture. Do NOT bind these callbacks yourself
-- when using this system -- see docs/api/input-system.md.
-- @param config  Optional config table (shallow-merged over defaults)
-- @return input instance
function input.new(config)
    config = config or {}
    local self = setmetatable({}, input)

    -- Buffer window (0 = disabled)
    self.bufferWindow = (config.bufferWindow ~= nil)
        and config.bufferWindow or DEFAULTS.bufferWindow

    -- Bindings: action -> { key1, key2, ... }
    self._bindings = {}
    local db = config.defaultBindings or DEFAULTS.defaultBindings
    for action, key in pairs(db) do
        self._bindings[action] = { key }
    end

    -- Buffer timestamps: action -> { timestamp, ... }
    self._buffers = {}

    -- Install Love2D hooks once per process
    if not _hooked then
        _hooked = true
        _oldKeypressed  = love.keypressed
        _oldKeyreleased = love.keyreleased

        love.keypressed = function(key, scancode, isrepeat)
            for i = 1, #_instances do
                _instances[i]:_onKeyPressed(key)
            end
            if _oldKeypressed then
                return _oldKeypressed(key, scancode, isrepeat)
            end
        end

        love.keyreleased = function(key, scancode)
            for i = 1, #_instances do
                _instances[i]:_onKeyReleased(key)
            end
            if _oldKeyreleased then
                return _oldKeyreleased(key, scancode)
            end
        end
    end

    table.insert(_instances, self)
    return self
end

-- ── Internal: Love2D callback handlers ───────────────────────────────

--- Record a key press timestamp for buffer support.
function input:_onKeyPressed(key)
    if self.bufferWindow <= 0 then return end
    local now = love.timer.getTime()
    for action, keys in pairs(self._bindings) do
        for _, k in ipairs(keys) do
            if k == key then
                if not self._buffers[action] then
                    self._buffers[action] = {}
                end
                table.insert(self._buffers[action], now)
                break
            end
        end
    end
end

--- Reserved for future use (e.g., release-based buffering).
function input:_onKeyReleased(key)
    -- no-op
end

-- ── Binding methods ──────────────────────────────────────────────────

--- Add one or more keys to an action. Duplicates are ignored.
-- @param action  Action name string
-- @param ...     One or more key/button names
function input:bind(action, ...)
    local keys = {...}
    if #keys == 0 then return end
    if not self._bindings[action] then
        self._bindings[action] = {}
    end
    for _, key in ipairs(keys) do
        local exists = false
        for _, k in ipairs(self._bindings[action]) do
            if k == key then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(self._bindings[action], key)
        end
    end
end

--- Remove a key from an action.
-- If key is omitted, all bindings for the action are removed.
-- @param action  Action name string
-- @param key     Optional key/button name to remove
function input:unbind(action, key)
    local bindings = self._bindings[action]
    if not bindings then return end

    if key == nil then
        self._bindings[action] = {}
    else
        for i = #bindings, 1, -1 do
            if bindings[i] == key then
                table.remove(bindings, i)
            end
        end
    end
end

--- Replace ALL bindings for an action with the given keys.
-- @param action  Action name string
-- @param ...     One or more key/button names (replaces all existing)
function input:rebind(action, ...)
    self._bindings[action] = {...}
end

-- ── Poll methods ─────────────────────────────────────────────────────

--- Check whether any key bound to an action is currently held.
-- Checks both keyboard and gamepad (when available).
-- @param action  Action name string
-- @return boolean
function input:isPressed(action)
    local keys = self._bindings[action]
    if not keys or #keys == 0 then return false end

    -- Keyboard check
    if love.keyboard then
        for _, key in ipairs(keys) do
            if love.keyboard.isDown(key) then
                return true
            end
        end
    end

    -- Gamepad check (conditional: love.joystick may be disabled)
    if love.joystick then
        local joysticks = love.joystick.getJoysticks()
        if #joysticks > 0 then
            for _, key in ipairs(keys) do
                for _, joy in ipairs(joysticks) do
                    if joy:isGamepadDown(key) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

--- Inverse of isPressed -- true when NO bound key is held.
-- @param action  Action name string
-- @return boolean
function input:isReleased(action)
    return not self:isPressed(action)
end

--- Check whether a bound key was pressed within the buffer window.
-- Requires bufferWindow > 0 in config.
-- @param action  Action name string
-- @return boolean
function input:isBuffered(action)
    if self.bufferWindow <= 0 then return false end
    local timestamps = self._buffers[action]
    if not timestamps or #timestamps == 0 then return false end
    return love.timer.getTime() - timestamps[#timestamps] <= self.bufferWindow
end

--- Get a list of all action names that are currently pressed.
-- @return table  Array of action name strings
function input:getPressedActions()
    local pressed = {}
    for action in pairs(self._bindings) do
        if self:isPressed(action) then
            table.insert(pressed, action)
        end
    end
    return pressed
end

-- ── Lifecycle ────────────────────────────────────────────────────────

--- Per-frame update. Trims expired buffer entries.
-- Call once per frame after handling input logic.
-- @param dt  Delta time in seconds
function input:update(dt)
    if dt <= 0 then return end
    if self.bufferWindow <= 0 then return end

    local cutoff = love.timer.getTime() - self.bufferWindow
    for action, timestamps in pairs(self._buffers) do
        while #timestamps > 0 and timestamps[1] < cutoff do
            table.remove(timestamps, 1)
        end
        if #timestamps == 0 then
            self._buffers[action] = nil
        end
    end
end

--- Clear all bindings and buffer state.
-- @return self  (for chaining)
function input:reset()
    self._bindings = {}
    self._buffers  = {}
    return self
end

-- ── Getters ──────────────────────────────────────────────────────────

--- Return the keys bound to an action (shallow copy).
-- @param action  Action name string
-- @return table|nil  Array of key names, or nil if unbound
function input:getBindings(action)
    local keys = self._bindings[action]
    if not keys then return nil end
    local copy = {}
    for _, k in ipairs(keys) do
        table.insert(copy, k)
    end
    return copy
end

return input
