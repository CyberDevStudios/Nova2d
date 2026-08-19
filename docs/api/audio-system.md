# Audio System

A channel-based audio manager with **source pooling**, **volume control**, **fades**, and **end-of-playback events**. Standalone module — no external dependencies beyond Love2D's audio API.

```lua
local audio = require("src.systems.audio")

local sound = audio.new()
```

## Quick start

```lua
local audio = require("src.systems.audio")

local sfx = audio.new()  -- defaults: "sfx" (pool 8) and "music" (pool 1) channels

local jump = love.audio.newSource("assets/jump.wav", "static")

function love.keypressed(key)
    if key == "space" then
        sfx:play("sfx", jump)          -- pooled: 8 simultaneous sounds max
    end
end

sfx:on("ended", function(channel, source)
    -- fired when a played source finishes on its own
end)

function love.update(dt)
    sfx:update(dt)  -- advances fades and detects ended sources
end
```

## Config

### `audio.new(config)`

All fields are optional.

| Field | Type | Default | Description |
|---|---|---|---|
| `channels` | table | `{ sfx = { volume = 1, pool = 8 }, music = { volume = 0.8, pool = 1 } }` | Channel definitions. Each entry: `{ volume = 0–1, pool = N }` where `pool` is the number of simultaneously playable sources |

```lua
-- Custom channels: one big SFX pool, two music slots, no defaults
local sound = audio.new({
    channels = {
        sfx    = { volume = 1,   pool = 16 },
        music  = { volume = 0.8, pool = 2  },
    },
})
```

## API

### `audio:play(channel, source, options)`

Plays a source on a channel, reusing a pooled slot.

- Options: `{ volume = 1, loop = false, pitch = 1 }`
- If the pool is exhausted, the least-recently-used slot is stolen (its source is stopped first)
- Effective volume = `master × channel volume × options.volume`
- Returns the pool slot used

### `audio:music(channel, source, options)`

Single-track playback: stops whatever is playing on the channel first, then plays.

- Options: `{ volume = 1, loop = true, pitch = 1 }`
- Configure the channel with `pool = 1` for classic music-track behavior

### `audio:stop(channel)`

Stops every source on the channel and frees its slots.

### `audio:stopAll()`

Stops every channel.

### `audio:setVolume(channel, volume)` / `audio:getVolume(channel)`

Sets/reads a channel's volume (0–1). Applied immediately to currently playing sources.

### `audio:setMasterVolume(volume)` / `audio:getMasterVolume()`

Sets/reads the master multiplier (0–1), applied across every channel.

### `audio:fade(channel, target, duration, cb)`

Fades a channel's volume toward `target` over `duration` seconds.

- Replaces any active fade on the same channel
- Fires `fade-complete(channel, target)` when done, then calls `cb(channel, target)` if given

```lua
sound:fade("music", 0, 2)          -- fade out over 2s
sound:fade("music", 0.8, 2, function()
    print("music back at full volume")
end)
```

### `audio:update(dt)`

Per-frame update. Call once per frame.

- Advances active fades
- Detects sources that finished playing and fires `ended(channel, source)`

### `audio:reset()`

Stops everything, clears fades, restores master volume to 1. Returns `self`.

## Events

Register listeners with `sound:on(event, callback)`.

| Event | Arguments | Fires |
|---|---|---|
| `ended` | `channel, source` | When a played source finishes on its own |
| `fade-complete` | `channel, target` | When a fade reaches its target volume |

## Notes

- All volume control is per-source; the module never touches Love2D's master volume (`love.audio.setVolume`)
- Fades animate the channel volume, so every source on the channel is affected
- Sources stopped manually (via `stop`/`stopAll`) do **not** fire `ended`