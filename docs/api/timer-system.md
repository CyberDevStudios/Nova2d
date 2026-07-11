# Timer System

A standalone module for **countdown** and **stopwatch** timing — pause, resume, tick events, and expiration detection. Works with any game loop, no external dependencies.

```lua
local timer = require("src.systems.timer")

-- Create with default config
local t = timer.new()
```

## Quick start

### Countdown

```lua
local timer = require("src.systems.timer")

local t = timer.new({ mode = "countdown", duration = 5 })  -- 5-second countdown

t:on("expired", function()
    print("Time's up!")
end)

function love.update(dt)
    t:update(dt)

    if t:isExpired() then
        -- restart for another round
        t:reset()
    end
end
```

### Stopwatch

```lua
local timer = require("src.systems.timer")

local t = timer.new({ mode = "stopwatch" })

t:on("tick", function(elapsed)
    print("Timer running:", elapsed, "seconds")
end)

function love.update(dt)
    t:update(dt)
end
```

## Config

### `timer.new(config)`

All fields are optional. Pass only what you want to override.

| Field | Type | Default | Description |
|---|---|---|---|
| `mode` | string | `"countdown"` | `"countdown"` — counts down to zero; `"stopwatch"` — counts up freely |
| `duration` | number | `1` | Duration in seconds. Countdown fires `expired` when this is reached |

```lua
-- 10-second countdown
local t = timer.new({ mode = "countdown", duration = 10 })

-- Free-running stopwatch
local t = timer.new({ mode = "stopwatch" })
```

## API

### `timer:update(dt)`

Core update. Call once per frame.

- Advances elapsed time by `dt` seconds
- Fires `tick(elapsed, remaining)` every frame
- In countdown mode, fires `expired()` when elapsed reaches duration
- No-op when paused or already expired

**Edge cases**:
- Negative `dt` values are silently ignored
- `duration = 0` countdown expires immediately on the first `update()` call

```lua
function love.update(dt)
    t:update(dt)
end
```

### `timer:pause()`

Pauses the timer. `update()` becomes a no-op until `resume()` is called.

```lua
t:pause()
```

### `timer:resume()`

Resumes a paused timer. Behavior depends on the timer's state:

| State | Behavior |
|---|---|
| Running (not paused, not expired) | No-op — timer continues as-is |
| Paused | Resumes from where it stopped |
| Expired (countdown reached 0) | Resets elapsed to 0 and starts fresh |

```lua
t:resume()
```

### `timer:reset()`

Resets all state to initial values: elapsed to 0, expired to false, paused to false.

**Returns**: `self` (for chaining).

```lua
t:reset()
```

### `timer:on(event, cb)`

Register an event listener. Returns the callback (useful for `table.remove()` to unregister later).

| Event | Payload | Fires when |
|---|---|---|
| `tick` | `elapsed, remaining` | Every `update()` frame while running |
| `expired` | — | Countdown reaches zero (countdown mode only) |

```lua
t:on("tick", function(elapsed, remaining)
    print(string.format("%.1f seconds elapsed, %.1f remaining", elapsed, remaining))
end)

t:on("expired", function()
    print("Countdown finished!")
end)
```

### Getters

| Method | Returns | Description |
|---|---|---|
| `:getElapsed()` | number | Seconds elapsed since start or last reset |
| `:getRemaining()` | number or `nil` | Seconds remaining (countdown only). `nil` in stopwatch mode |
| `:getProgress()` | number or `nil` | 0–1 progress to expiration (countdown only). `nil` in stopwatch mode |
| `:isRunning()` | boolean | `true` when not paused and not expired |
| `:isExpired()` | boolean | `true` when countdown has reached zero. Always `false` in stopwatch mode |

```lua
print("Elapsed:", t:getElapsed())
print("Remaining:", t:getRemaining())
print("Progress:", t:getProgress())
print("Running:", t:isRunning())
print("Expired:", t:isExpired())
```

## Examples

### Power-up timer (countdown)

A temporary speed boost that lasts 3 seconds.

```lua
local speedBoost = timer.new({ duration = 3 })

function apply_speed_boost(player)
    player.speed = player.baseSpeed * 2
    speedBoost:reset()
end

function love.update(dt)
    speedBoost:update(dt)

    if speedBoost:isExpired() then
        player.speed = player.baseSpeed
    end
end
```

### Race timer (stopwatch)

Track how long a player takes to finish a level.

```lua
local raceTimer = timer.new({ mode = "stopwatch" })

function love.update(dt)
    if not raceFinished then
        raceTimer:update(dt)
    end
end

function on_finish_line_crossed()
    raceFinished = true
    print("Finish time:", raceTimer:getElapsed(), "seconds")
end
```

### Pause-safe game clock

Pause and resume the timer when the game is paused.

```lua
function love.update(dt)
    if gamePaused then return end

    gameTimer:update(dt)
end

function love.keypressed(key)
    if key == "escape" then
        gamePaused = not gamePaused
        if gamePaused then
            gameTimer:pause()
        else
            gameTimer:resume()
        end
    end
end
```

### Duration-zero edge case

A `duration = 0` countdown expires instantly on the first update — useful for one-frame triggers.

```lua
local instant = timer.new({ duration = 0 })

instant:on("expired", function()
    print("Fires immediately on first love.update()")
end)

-- First update → expired fires
instant:update(0.016)
-- Second update → no-op (already expired)
instant:update(0.016)
```
