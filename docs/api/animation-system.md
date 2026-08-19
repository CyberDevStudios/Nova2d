# Animation System

A sprite-sheet animation module with **frame events**, **loop control**, and **flipping** — built on top of `anim8` (already bundled with Nova2D). Works with any game loop, zero configuration beyond your sprite sheet.

```lua
local animation = require("src.systems.animation")

local walk = animation.new({
    image       = playerSheet,      -- love.Image
    frameWidth  = 32,
    frameHeight = 32,
    frames      = {1, 2, 3, 4},     -- grid indices
    fps         = 8,
})
```

## Quick start

```lua
local animation = require("src.systems.animation")

local player = {
    x = 100, y = 100,
    anim = animation.new({
        image       = love.graphics.newImage("assets/player.png"),
        frameWidth  = 32,
        frameHeight = 32,
        frames      = {1, 2, 3, 4},
        fps         = 8,
        loop        = true,
    }),
}

player.anim:on("frame", function(position)
    -- position is the 1-based index into the configured frame list
end)

player.anim:on("complete", function()
    -- fires once per finished cycle (looping) or once at the end (non-looping)
end)

function love.update(dt)
    player.anim:update(dt)
end

function love.draw()
    love.graphics.draw(playerSheet, player.anim:getQuad(), player.x, player.y)
end
```

## Config

### `animation.new(config)`

| Field | Type | Default | Description |
|---|---|---|---|
| `image` | love.Image | — (required) | The sprite sheet |
| `frameWidth` | number | — (required) | Frame width in pixels |
| `frameHeight` | number | — (required) | Frame height in pixels |
| `frames` | table | all frames | Grid indices to play, e.g. `{1, 2, 3, 4}`. Indices run left-to-right, top-to-bottom starting at 1 |
| `durations` | number \| table | `1 / fps` | Seconds per frame. A number applies to every frame; a table sets per-frame durations |
| `fps` | number | `8` | Frames per second, used only when `durations` is not given |
| `loop` | boolean | `true` | `true` cycles forever; `false` plays once and stops at the last frame |
| `flipX` | boolean | `false` | Flip horizontally (uses the sheet's mirrored quads) |
| `flipY` | boolean | `false` | Flip vertically |

```lua
-- One-shot punch animation (2 frames, 0.1s each, plays once)
local punch = animation.new({
    image = sheet, frameWidth = 32, frameHeight = 32,
    frames = {5, 6}, durations = 0.1, loop = false,
})
```

## API

### `animation:update(dt)`

Core update. Call once per frame.

- Advances the animation by `dt` seconds
- Fires `frame(position)` whenever the displayed frame changes
- Fires `complete()` when a cycle finishes (see events below)
- No-op after a non-looping animation has finished

### `animation:play()`

Restarts from the first frame, even if the animation had finished. Returns `self` for chaining.

### `animation:pause()`

Stops advancing on the current frame.

### `animation:resume()`

Resumes playback. If the animation had finished, restarts from the first frame. Returns `self`.

### `animation:stop()`

Stops and rewinds to the first frame. Returns `self`.

### `animation:reset()`

Alias of `stop()` (rewind to first frame). Returns `self`.

### `animation:isPlaying()`

Returns `true` while the animation is advancing (not paused, not finished).

### `animation:getFrame()`

Current frame position — the 1-based index into the configured frame list.

### `animation:getQuad()`

Current frame quad, ready for `love.graphics.draw(image, quad, x, y)`.

### `animation:getDimensions()`

Returns the frame `width, height` in pixels.

## Events

Register listeners with `anim:on(event, callback)`.

| Event | Arguments | Fires |
|---|---|---|
| `frame` | `position` | Whenever the displayed frame changes |
| `complete` | — | Once per finished cycle when `loop = true`; exactly once when `loop = false` |

## Notes

- The module wraps `anim8` (kikito/anim8 v2.3.0), which is installed automatically by `love gestor/ install`
- Grid indices map to sheet positions left-to-right, top-to-bottom: index 1 is the top-left frame
- For non-looping animations, `update(dt)` becomes a no-op after `complete()` fires; call `play()` to restart