# Camera System

A standalone module for a **target-following camera** with smooth lerp, screen shake, zoom controls, and viewport bounds — all through standard `love.graphics` transforms. No external dependencies.

```lua
local camera = require("src.systems.camera")

-- Create with default config
local cam = camera.new()
```

## Quick start

```lua
local camera = require("src.systems.camera")

function love.load()
    cam = camera.new({ smoothing = 0.1 })
end

function love.update(dt)
    -- Camera follows the player (must have .x and .y)
    cam:update(dt)
end

function love.draw()
    cam:attach()
    -- Everything drawn here is in world coordinates
    love.graphics.circle("fill", player.x, player.y, 20)
    cam:detach()

    -- HUD drawn here (in screen coordinates)
    love.graphics.print("HP: 100", 10, 10)
end
```

## Config

### `camera.new(config)`

All fields are optional. Pass only what you want to override.

| Field | Type | Default | Description |
|---|---|---|---|
| `smoothing` | number | `0.1` | Lerp factor for target-follow (0–1, lower = smoother) |
| `zoom` | number | `1` | Initial zoom level |
| `minZoom` | number | `0.25` | Minimum zoom (zoom-in limit) |
| `maxZoom` | number | `4` | Maximum zoom (zoom-out limit) |
| `bounds` | table / nil | `nil` | `{x, y, w, h}` in world coordinates, or `nil` for unbounded |

```lua
-- Smooth, tightly-following camera
local cam = camera.new({
    smoothing = 0.05,
    minZoom = 0.5,
    maxZoom = 2,
})

-- Camera clamped to a 3200×1800 level
local cam = camera.new({
    bounds = { 0, 0, 3200, 1800 },
})
```

## API

### `camera:update(dt)`

Core update. Call once per frame.

- Lerps the camera position toward the target using a frame-rate independent formula
- Decays the shake effect (fires `shakeEnd` when complete)
- Clamps camera position to bounds if configured

```lua
function love.update(dt)
    cam:update(dt)
end
```

### `camera:follow(target)`

Start following a target. The target must have `.x` and `.y` fields. On first call, snaps the camera instantly to the target position.

Call `cam:follow(nil)` or `cam:follow()` to stop following — the camera stays at its current position.

```lua
cam:follow(player)    -- follow the player
cam:follow(boss)      -- switch to boss
cam:follow()          -- stop following, stay put
```

### `camera:attach()`

Apply camera transforms. Must be called **before** drawing the game world.

- Pushes the transform stack (`love.graphics.push()`)
- Translates origin to screen center
- Applies zoom (`love.graphics.scale()`)
- Translates to camera position
- Applies screen-space shake offset (if shaking)

Must be paired with `:detach()` after world drawing.

```lua
function love.draw()
    cam:attach()
    -- ... draw world entities ...
    cam:detach()
    -- ... draw HUD / UI ...
end
```

### `camera:detach()`

Restore the transform stack (`love.graphics.pop()`). Call after drawing the game world, before drawing any HUD or UI that should stay fixed on screen.

### `camera:startShake(intensity, duration)`

Start a screen shake effect. The shake offset is applied in **screen-space pixels** each frame, so the effect is visible regardless of zoom level.

| Parameter | Type | Description |
|---|---|---|
| `intensity` | number | Maximum pixel offset (decays to zero) |
| `duration` | number | Total duration in seconds |

The intensity decays **linearly** to zero over the duration.

```lua
-- Shake on explosion
cam:startShake(10, 0.5)

-- Heavy shake on boss hit
cam:startShake(20, 1.0)
```

### `camera:setZoom(zoom)`

Set the zoom level. Automatically clamped to `[minZoom, maxZoom]`.

```lua
cam:setZoom(2)     -- zoom in 2x
cam:setZoom(0.5)   -- zoom out 2x
cam:setZoom(100)   -- clamped to maxZoom (4)
```

### `camera:setBounds(x, y, w, h)`

Constrain the camera so the viewport stays within the given rectangular area. Useful for keeping the camera inside a level.

```lua
-- Level bounds: 0–3200 wide, 0–1800 tall
cam:setBounds(0, 0, 3200, 1800)
```

### `camera:clearBounds()`

Remove all viewport bounds. The camera can move freely again.

```lua
cam:clearBounds()
```

### `camera:reset()`

Reset all runtime state to initial values:
- Position to `(0, 0)`
- Zoom to config default
- Stop following any target
- Stop any active shake

Config fields (`smoothing`, `minZoom`, `maxZoom`, `bounds`) are preserved.

**Returns**: `self` (for chaining).

```lua
cam:reset()
```

### `camera:on(event, cb)`

Register an event listener. Returns the callback (useful for `table.remove()` to unregister later).

| Event | Payload | Fires when |
|---|---|---|
| `shakeStart` | `intensity, duration` | A shake effect begins |
| `shakeEnd` | — | The shake effect ends (timer reaches 0) |

```lua
cam:on("shakeStart", function(intensity, duration)
    print("Shake started:", intensity, "for", duration, "s")
end)

cam:on("shakeEnd", function()
    print("Camera steady")
end)
```

### Getters

| Method | Returns | Description |
|---|---|---|
| `:getPosition()` | `x, y` | Camera center in world coordinates |
| `:getZoom()` | number | Current zoom level |
| `:isShaking()` | boolean | `true` while shake is active |
| `:getViewRect()` | `x, y, w, h` | Visible world rectangle (top-left + dimensions) |

```lua
local cx, cy = cam:getPosition()
local zoom = cam:getZoom()
if cam:isShaking() then
    print("Camera is shaking!")
end
local left, top, vw, vh = cam:getViewRect()
```

`getViewRect()` is useful for culling off-screen entities:

```lua
local l, t, w, h = cam:getViewRect()
for _, entity in ipairs(entities) do
    if entity.x > l - 50 and entity.x < l + w + 50
    and entity.y > t - 50 and entity.y < t + h + 50 then
        entity:draw()
    end
end
```

## Examples

### Setting up a player-following camera

```lua
local camera = require("src.systems.camera")

function love.load()
    player = { x = 400, y = 300 }
    cam = camera.new({ smoothing = 0.1, bounds = { 0, 0, 3200, 1800 } })
    cam:follow(player)
end

function love.update(dt)
    -- Move player with arrow keys
    if love.keyboard.isDown("left")  then player.x = player.x - 200 * dt end
    if love.keyboard.isDown("right") then player.x = player.x + 200 * dt end
    if love.keyboard.isDown("up")    then player.y = player.y - 200 * dt end
    if love.keyboard.isDown("down")  then player.y = player.y + 200 * dt end

    cam:update(dt)
end

function love.draw()
    cam:attach()
    -- Draw level tiles, entities, particles (world space)
    love.graphics.rectangle("line", 0, 0, 3200, 1800)  -- level bounds
    love.graphics.circle("fill", player.x, player.y, 16)
    cam:detach()

    -- HUD (screen space)
    love.graphics.print("Player: " .. math.floor(player.x) .. ", " .. math.floor(player.y), 10, 10)
end
```

### Shake on explosion

```lua
cam:on("shakeStart", function()
    play_sound("rumble")
end)

-- Triggered when an explosion happens
function on_explosion(position, radius)
    spawn_particles(position, radius)
    cam:startShake(15, 0.6)
end
```

### Zoom with scroll wheel

```lua
function love.wheelmoved(x, y)
    local current = cam:getZoom()
    cam:setZoom(current + y * 0.25)
end
```

### Switching targets

```lua
-- During a boss fight, the camera switches focus
function on_boss_spawn(boss)
    cam:follow(boss)
end

function on_boss_defeated()
    cam:follow(player)
end
```

## Per-frame setup (recommended pattern)

```lua
function love.update(dt)
    -- 1. Update game logic (move entities, etc.)
    update_player(dt)
    update_enemies(dt)

    -- 2. Update camera (lerp, shake decay, bounds)
    cam:update(dt)
end

function love.draw()
    -- 3. Attach camera and draw world
    cam:attach()
    draw_level()
    draw_entities()
    cam:detach()

    -- 4. Draw HUD in screen space
    draw_hud()
end
```
