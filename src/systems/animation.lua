-- Nova2D — Animation System
-- src/systems/animation.lua
-- Sprite-sheet animation wrapper over anim8 (bundled dependency).
-- Provides frame/complete events, fps control, flipping, and the
-- standard Nova2D new/update/reset lifecycle.

local anim8 = require("anim8")

local animation = {}
animation.__index = animation

local DEFAULTS = {
    image        = nil,   -- love.Image: sprite sheet
    frameWidth   = nil,   -- px per frame
    frameHeight  = nil,   -- px per frame
    frames       = nil,   -- grid indices, e.g. {1,2,3,4}; nil = all frames
    durations    = nil,   -- number or per-frame table; nil = 1/fps
    fps          = 8,
    loop         = true,
    flipX        = false,
    flipY        = false,
}

--- Create a new animation instance.
-- @param config  Config table (image, frameWidth, frameHeight required)
-- @return animation instance
function animation.new(config)
    config = config or {}
    local self = setmetatable({}, animation)

    -- Merge config over defaults. NOTE: a plain `a and b or c` idiom is
    -- avoided because it breaks when the config value is `false` (e.g.
    -- loop = false would silently fall back to the default `true`).
    for k, v in pairs(DEFAULTS) do
        if config[k] ~= nil then
            self[k] = config[k]
        else
            self[k] = v
        end
    end

    -- Required fields (no default; nil-valued defaults are not
    -- visited by pairs, so these are copied explicitly)
    self.image       = config.image
    self.frameWidth  = config.frameWidth
    self.frameHeight = config.frameHeight
    self.frames      = config.frames
    self.durations   = config.durations

    assert(self.image, "animation.new: config.image (love.Image) is required")
    assert(self.frameWidth and self.frameHeight, "animation.new: config.frameWidth and frameHeight are required")

    -- Build the frame grid from the sprite sheet
    local grid = anim8.newGrid(
        self.frameWidth, self.frameHeight,
        self.image:getWidth(), self.image:getHeight()
    )

    local gridWidth = math.floor(self.image:getWidth() / self.frameWidth)
    local gridHeight = math.floor(self.image:getHeight() / self.frameHeight)

    -- anim8's getFrames takes (x-range, y-range) pairs, so linear
    -- indices are mapped to grid coordinates here.
    local function frameAt(idx)
        local x = (idx - 1) % gridWidth + 1
        local y = math.floor((idx - 1) / gridWidth) + 1
        return grid:getFrames(x, y)[1]
    end

    local allFrames = {}
    for i = 1, gridWidth * gridHeight do
        allFrames[i] = i
    end

    local indices = self.frames or allFrames
    local frames = {}
    for i, idx in ipairs(indices) do
        frames[i] = frameAt(idx)
    end

    local durations = self.durations or (1 / self.fps)
    -- anim8 fires onLoop whenever a full cycle completes. Looping
    -- animations re-fire per cycle; non-looping finish exactly once.
    local onLoop = function()
        if self.loop then
            self:_fire("complete")
        else
            if not self._finished then
                self._finished = true
                self:_fire("complete")
            end
        end
    end
    self.anim = anim8.newAnimation(frames, durations, onLoop)
    self._lastPos = 1
    self._finished = false

    if self.flipX then self.anim:flipH() end
    if self.flipY then self.anim:flipV() end

    return self
end

--- Per-frame update.
-- Advances the animation by dt seconds and fires events when the
-- displayed frame changes or a cycle completes.
-- @param dt  Delta time in seconds
function animation:update(dt)
    if dt <= 0 then return end
    if self._finished then return end

    self.anim:update(dt)

    -- Frame-change event
    if self.anim.position ~= self._lastPos then
        self._lastPos = self.anim.position
        self:_fire("frame", self.anim.position)
    end
end

--- Play from the first frame.
-- Restarts the animation even if it had finished.
-- @return self  (for chaining)
function animation:play()
    self._finished = false
    self.anim:gotoFrame(1)
    self.anim:resume()
    return self
end

--- Pause the animation (keeps the current frame).
function animation:pause()
    self.anim:pause()
end

--- Resume playback.
-- If the animation had finished, restarts from the first frame.
-- @return self  (for chaining)
function animation:resume()
    if self._finished then
        return self:play()
    end
    self.anim:resume()
    return self
end

--- Stop and rewind to the first frame.
-- @return self  (for chaining)
function animation:stop()
    self.anim:pause()
    self.anim:gotoFrame(1)
    self._finished = false
    self._lastPos = 1
    return self
end

--- Reset to initial state (stop + rewind).
-- @return self  (for chaining)
function animation:reset()
    return self:stop()
end

-- ── Events ─────────────────────────────────────────────────────────

--- Register an event listener.
-- Supported events: frame(position), complete()
-- @param event  Event name string
-- @param cb     Callback function
-- @return function  The callback (for use with table.remove)
function animation:on(event, cb)
    if not self._callbacks then
        self._callbacks = {}
    end
    if not self._callbacks[event] then
        self._callbacks[event] = {}
    end
    table.insert(self._callbacks[event], cb)
    return cb
end

function animation:_fire(event, ...)
    local cbs = self._callbacks and self._callbacks[event]
    if cbs then
        for _, cb in ipairs(cbs) do
            cb(...)
        end
    end
end

-- ── Getters ─────────────────────────────────────────────────────────

--- Whether the animation is actively playing (not paused, not finished).
function animation:isPlaying()
    return self.anim.status == "playing" and not self._finished
end

--- Current frame index (1-based).
-- @return number  Position in the configured frame list
function animation:getFrame()
    return self.anim.position
end

--- Current frame quad, ready for love.graphics.draw.
-- @return Quad
function animation:getQuad()
    return self.anim.frames[self.anim.position]
end

--- Frame dimensions in pixels.
-- @return width, height
function animation:getDimensions()
    return self.anim:getDimensions()
end

return animation