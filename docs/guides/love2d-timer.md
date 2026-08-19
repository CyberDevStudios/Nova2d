# Love2D Timers — Countdown, Stopwatch & Delays in Your Game

Love2D has no built-in timer object — the classic pattern is accumulating `dt` in a local variable, or diffing `love.timer.getTime()` for a stopwatch. Nova2D wraps that into a proper Timer system: countdown and stopwatch modes, pause/resume, tick events, and expiration detection, all frame-rate independent.

## The vanilla Love2D way

A countdown is just a variable you accumulate in `love.update(dt)` and reset when it reaches its target:

```lua
local elapsed = 0
local duration = 5

function love.update(dt)
    elapsed = elapsed + dt

    if elapsed >= duration then
        print("Time's up!")
        elapsed = 0
    end
end
```

For a stopwatch (or measuring elapsed time anywhere), `love.timer.getTime()` returns seconds since the game started:

```lua
local startTime = love.timer.getTime()

function love.update()
    local elapsed = love.timer.getTime() - startTime
    print("Elapsed:", elapsed)
end
```

> **Note:** `love.timer.getDelta()` gives you the same value as the `dt` passed to `love.update(dt)` — it's the frame delta, not a timer. Manual accumulation is fine for one timer, but grows repetitive once you need several, or pause support.

## The Nova2D way

Nova2D's Timer system turns that pattern into an object with events:

```lua
local timer = require("src.systems.timer")

local t = timer.new({ mode = "countdown", duration = 5 })

t:on("expired", function()
    print("Time's up!")
end)

function love.update(dt)
    t:update(dt)
end
```

Pause and resume are built in — no manual flag checks:

```lua
t:pause()     -- stops advancing until resume()
t:resume()    -- continues from where it stopped
```

A free-running stopwatch is the same API with a different mode:

```lua
local race = timer.new({ mode = "stopwatch" })

function love.update(dt)
    race:update(dt)
end

print(race:getElapsed())  -- seconds since start
```

## Vanilla → Nova2D

| Task | Vanilla Love2D | Nova2D |
|---|---|---|
| Countdown | Accumulate `dt` in a local, compare against a target | `timer.new({ mode = "countdown", duration = 5 })` |
| Stopwatch | `love.timer.getTime()` start/diff | `timer.new({ mode = "stopwatch" })` |
| Pause / resume | Manual flag + conditional accumulation | `t:pause()` / `t:resume()` |
| Expiration callback | Manual `if elapsed >= duration` check | `t:on("expired", fn)` |
| Frame-rate independence | Manual — you must accumulate `dt` yourself | Automatic — the timer is driven by `dt` |

## Next step

The timer is a standalone module: no hump, no Nova2D bootstrapping, works in any game loop. See the [Timer System API](../api/timer-system.md) for the full reference: `tick`/`expired` events, getters (`getElapsed`, `getRemaining`, `getProgress`), and edge cases.