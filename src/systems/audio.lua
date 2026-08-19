-- Nova2D — Audio System
-- src/systems/audio.lua
-- Channel-based audio manager with source pooling, volume control,
-- fades, and end-of-playback events. Standalone module, no deps.

local audio = {}
audio.__index = audio

local DEFAULT_CHANNELS = {
    sfx   = { volume = 1,   pool = 8 },
    music = { volume = 0.8, pool = 1 },
}

local function mergeChannels(configChannels)
    local merged = {}
    -- Start from defaults, then override with configured channels
    for name, opts in pairs(DEFAULT_CHANNELS) do
        merged[name] = { volume = opts.volume, pool = opts.pool }
    end
    if configChannels then
        for name, opts in pairs(configChannels) do
            local base = merged[name] or { volume = 1, pool = 8 }
            merged[name] = {
                volume = (opts.volume ~= nil) and opts.volume or base.volume,
                pool   = (opts.pool   ~= nil) and opts.pool   or base.pool,
            }
        end
    end
    return merged
end

--- Create a new audio manager.
-- @param config  Optional config table (shallow-merged over defaults)
-- @return audio instance
function audio.new(config)
    config = config or {}
    local self = setmetatable({}, audio)

    self._master   = 1
    self._tick     = 0
    self._fades    = {}
    self._callbacks = {}
    self._channels = mergeChannels(config.channels)

    -- Pre-allocate source slots per channel
    for name, opts in pairs(self._channels) do
        local slots = {}
        for i = 1, opts.pool do
            slots[i] = {
                source  = nil,
                inUse   = false,
                lastUsed = 0,
                baseVol = 1,
                _ended  = false,
            }
        end
        self._channels[name].slots = slots
    end

    return self
end

--- Play a source on a channel (pooled).
-- Steals the least-recently-used slot when the pool is exhausted.
-- @param channel   Channel name (e.g. "sfx", "music")
-- @param source    love.Source
-- @param options   Optional: { volume = 1, loop = false, pitch = 1 }
-- @return slot  The pool slot used
function audio:play(channel, source, options)
    options = options or {}
    local chan = self._channels[channel]
    if not chan then
        error("audio:play: unknown channel '" .. tostring(channel) .. "'", 2)
    end

    local slot = self:_findSlot(chan)
    if slot.source and slot.source:isPlaying() then
        slot.source:stop()
    end

    slot.baseVol = options.volume or 1
    slot.source  = source
    slot.inUse   = true
    slot._ended  = false
    slot.lastUsed = self._tick
    self._tick = self._tick + 1

    source:setVolume(self:_effectiveVolume(chan, slot))
    source:setLooping(options.loop or false)
    if options.pitch then source:setPitch(options.pitch) end
    source:play()

    return slot
end

--- Play a source as the single track of a channel (music semantics).
-- Stops whatever is playing on the channel first, then plays.
-- @param channel   Channel name (configure with pool = 1)
-- @param source    love.Source
-- @param options   Optional: { volume = 1, loop = true, pitch = 1 }
-- @return slot  The pool slot used
function audio:music(channel, source, options)
    local chan = self._channels[channel]
    if not chan then
        error("audio:music: unknown channel '" .. tostring(channel) .. "'", 2)
    end

    for _, slot in ipairs(chan.slots) do
        if slot.inUse and slot.source and slot.source:isPlaying() then
            slot.source:stop()
            slot.inUse = false
        end
    end

    options = options or {}
    options.loop = (options.loop ~= false)
    return self:play(channel, source, options)
end

--- Stop all sources on a channel.
-- @param channel  Channel name
function audio:stop(channel)
    local chan = self._channels[channel]
    if not chan then return end
    for _, slot in ipairs(chan.slots) do
        if slot.inUse then
            if slot.source then slot.source:stop() end
            slot.inUse = false
        end
    end
end

--- Stop every channel.
function audio:stopAll()
    for name in pairs(self._channels) do
        self:stop(name)
    end
end

--- Set the volume of a channel (applied to currently playing sources).
-- @param channel  Channel name
-- @param volume   0–1
function audio:setVolume(channel, volume)
    local chan = self._channels[channel]
    if not chan then return end
    chan.volume = volume
    self:_applyVolumes(chan)
end

--- Current volume of a channel.
-- @param channel  Channel name
-- @return number  0–1
function audio:getVolume(channel)
    local chan = self._channels[channel]
    return chan and chan.volume or 0
end

--- Set the master volume multiplier (applied to every channel).
-- @param volume  0–1
function audio:setMasterVolume(volume)
    self._master = volume
    for _, chan in pairs(self._channels) do
        self:_applyVolumes(chan)
    end
end

--- Current master volume multiplier.
-- @return number  0–1
function audio:getMasterVolume()
    return self._master
end

--- Fade a channel's volume toward a target over a duration.
-- Replaces any active fade on the same channel.
-- @param channel    Channel name
-- @param target     0–1
-- @param duration   Seconds
-- @param cb         Optional completion callback
function audio:fade(channel, target, duration, cb)
    local chan = self._channels[channel]
    if not chan then return end
    self._fades[channel] = {
        from    = chan.volume,
        target  = target,
        duration = math.max(0.0001, duration or 1),
        elapsed = 0,
        cb      = cb,
    }
end

--- Per-frame update.
-- Advances fades and detects end-of-playback on active sources.
-- @param dt  Delta time in seconds
function audio:update(dt)
    if dt <= 0 then return end

    -- Fades
    for channel, fade in pairs(self._fades) do
        local chan = self._channels[channel]
        fade.elapsed = fade.elapsed + dt
        local t = math.min(1, fade.elapsed / fade.duration)
        chan.volume = fade.from + (fade.target - fade.from) * t
        self:_applyVolumes(chan)

        if t >= 1 then
            self._fades[channel] = nil
            self:_fire("fade-complete", channel, fade.target)
            if fade.cb then fade.cb(channel, fade.target) end
        end
    end

    -- End-of-playback detection (poll-based: a source that finished
    -- playing reports isPlaying() == false; the slot is then freed)
    for name, chan in pairs(self._channels) do
        for _, slot in ipairs(chan.slots) do
            if slot.inUse and not slot._ended then
                if slot.source and not slot.source:isPlaying() then
                    slot._ended = true
                    slot.inUse  = false
                    self:_fire("ended", name, slot.source)
                end
            end
        end
    end
end

--- Reset the manager: stop everything, clear fades, restore master volume.
-- @return self  (for chaining)
function audio:reset()
    self:stopAll()
    self._fades = {}
    self._master = 1
    return self
end

-- ── Events ─────────────────────────────────────────────────────────

--- Register an event listener.
-- Supported events: ended(channel, source), fade-complete(channel, target)
-- @param event  Event name string
-- @param cb     Callback function
-- @return function  The callback (for use with table.remove)
function audio:on(event, cb)
    if not self._callbacks[event] then
        self._callbacks[event] = {}
    end
    table.insert(self._callbacks[event], cb)
    return cb
end

function audio:_fire(event, ...)
    local cbs = self._callbacks[event]
    if cbs then
        for _, cb in ipairs(cbs) do
            cb(...)
        end
    end
end

-- ── Internals ───────────────────────────────────────────────────────

function audio:_findSlot(chan)
    -- Prefer a free slot; otherwise steal the least-recently-used one
    local oldest = nil
    for _, slot in ipairs(chan.slots) do
        if not slot.inUse then
            return slot
        end
        if not oldest or slot.lastUsed < oldest.lastUsed then
            oldest = slot
        end
    end
    return oldest
end

function audio:_effectiveVolume(chan, slot)
    return self._master * chan.volume * slot.baseVol
end

function audio:_applyVolumes(chan)
    for _, slot in ipairs(chan.slots) do
        if slot.inUse and slot.source then
            slot.source:setVolume(self:_effectiveVolume(chan, slot))
        end
    end
end

return audio