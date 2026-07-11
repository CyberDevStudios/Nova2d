# Jump System

A standalone module giving any game entity **coyote time, jump buffering, variable-height jumps, and multi-jump** — no physics engine required. You provide collision (set `grounded`), the system handles velocity and input timing.

```lua
local jump = require("src.systems.jump")

-- Create with default config
local j = jump.new()
```

## Quick start

```lua
local jump = require("src.systems.jump")

function love.load()
    player = { x = 400, y = 300 }
    j = jump.new()
end

function love.update(dt)
    -- 1. Resolve collision — tell the system if we're on the ground
    j.grounded = check_grounded(player)

    -- 2. Handle input
    if love.keyboard.isDown("space") and not wasSpaceDown then
        j:jump()         -- returns velocity or nil
    end
    if not love.keyboard.isDown("space") and wasSpaceDown then
        j:release()      -- variable-height cut
    end
    wasSpaceDown = love.keyboard.isDown("space")

    -- 3. Advance the system
    j:update(dt)

    -- 4. Apply velocity to position
    player.y = player.y + j:getVelocity() * dt
end

function love.draw()
    love.graphics.circle("fill", player.x, player.y, 20)
end
```

## Config

### `jump.new(config)`

All fields are optional. Pass only what you want to override.

| Field | Type | Default | Description |
|---|---|---|---|
| `gravity` | number | `800` | Downward acceleration in pixels/s² |
| `jumpVelocity` | number | `-400` | Upward velocity on jump (negative = up) |
| `maxJumps` | number | `1` | Total jumps allowed before landing |
| `coyoteTime` | number | `0.1` | Grace period after leaving ground (seconds) |
| `bufferTime` | number | `0.1` | How long to buffer a jump input before landing (seconds) |
| `variableHeight` | boolean | `true` | When true, `release()` cuts upward velocity by 50% |

```lua
-- Double jump, no coyote, full-height only
local j = jump.new({
    maxJumps = 2,
    coyoteTime = 0,
    variableHeight = false,
})
```

## Writable properties

Set these **every frame** before calling `update()`. The system reads them during the update step.

| Property | Type | Default | Description |
|---|---|---|---|
| `.grounded` | boolean | `false` | `true` when the entity stands on solid ground |
| `.gravityMultiplier` | number | `1.0` | Scales gravity per frame (e.g. 0.5 for low-gravity zones) |

```lua
function love.update(dt)
    -- Underwater zone — reduce gravity
    j.gravityMultiplier = player.underwater and 0.3 or 1.0

    j.grounded = check_grounded(player)
    j:update(dt)
end
```

## API

### `jump:update(dt)`

Core update. Call once per frame **after** setting `.grounded` and handling input.

- Applies gravity (when `grounded` is `false`)
- Detects grounded → airborne and airborne → grounded transitions
- Ticks coyote timer and fires `leftGround` / `landed` events
- Ticks buffer timer and fires `jumpBufferExpired` when it expires
- Executes a buffered jump when landing

### `jump:jump()`

Attempt a jump. Call on the frame the jump key is pressed (not held).

**Returns**:
- `number` — the applied Y velocity (same as `jumpVelocity`) on success
- `nil` — if the jump cannot execute (no jumps left, not ground-able)

**Auto-buffering**: when called while airborne with no jumps remaining, the input is stored for `bufferTime` seconds. If the entity lands within that window, the jump fires automatically.

```lua
if key_pressed("space") then
    local vel = j:jump()
    if vel then
        -- jump succeeded — play sound, trigger animation
    end
end
```

### `jump:release()`

Call when the jump key is **released**. Only meaningful when `variableHeight` is `true` and the entity is still ascending. Cuts upward velocity by 50% for a short hop.

```lua
if key_released("space") then
    j:release()
end
```

### `jump:reset()`

Resets all internal state to initial values: velocity to 0, jumps used to 0, state to `idle`, timers cleared.

**Returns**: `self` (for chaining).

### `jump:on(event, cb)`

Register an event listener. Returns the callback (useful for `table.remove()` to unregister later).

| Event | Payload | Fires when |
|---|---|---|
| `jumped` | `velocityY` | A jump actually executes (via `:jump()` or buffered trigger) |
| `landed` | — | The entity transitions from airborne to grounded |
| `leftGround` | — | The entity transitions from grounded to airborne |
| `jumpBufferExpired` | — | A buffered jump input times out before landing |

```lua
j:on("jumped", function(vel)
    print("Jumped with velocity:", vel)
    play_sound("jump")
end)

j:on("landed", function()
    play_sound("land")
end)

j:on("jumpBufferExpired", function()
    -- visual feedback: "missed" indicator
end)
```

### Getters

| Method | Returns | Description |
|---|---|---|
| `:getVelocity()` | number | Current Y velocity in pixels/s (positive = downward) |
| `:isGrounded()` | boolean | Mirrors the `.grounded` property |
| `:getJumpsUsed()` | number | Jumps consumed since last landing |
| `:getCoyoteTimeRemaining()` | number | Seconds of coyote left (0 = expired) |
| `:getBufferTimeRemaining()` | number | Seconds of buffer left (0 = expired or none) |

## State machine

The system tracks three internal states:

```
┌──────────┐   jump()    ┌───────────┐  release() /   ┌──────────┐
│   idle   │ ──────────→ │ charging  │  peak reached   │ airborne │
│ (ground) │             │ (ascend)  │ ──────────────→ │  (fall)  │
└──────────┘             └───────────┘                 └──────────┘
     ↑                                                     │
     └─────────────────── landed() ────────────────────────┘
```

- **idle** — entity is grounded and waiting for input
- **charging** — jump pressed, ascending, variable-height window active
- **airborne** — falling, gravity applied each frame

## Examples

### Coyote time in action

The player walks off a ledge but presses jump within 0.1 seconds — the jump still works.

```lua
local j = jump.new({ coyoteTime = 0.1 })

-- Even though grounded went to false last frame,
-- pressing jump within 100ms still triggers a full jump.
function love.keypressed(key)
    if key == "space" then
        j:jump()
    end
end
```

### Jump buffer in action

The player presses jump slightly before landing — the input is stored and executes automatically on contact.

```lua
local j = jump.new({ bufferTime = 0.1 })

-- Player is falling. Presses space 50ms before hitting the ground.
-- The jump is buffered. On the frame grounded becomes true,
-- the jump fires automatically (feels responsive).
```

### Multi-jump (double/triple jump)

```lua
local j = jump.new({ maxJumps = 2 })

-- First press (grounded or coyote): first jump, jumpsUsed = 1
-- Second press (airborne): second jump, jumpsUsed = 2
-- Third press (airborne): blocked (2 >= maxJumps)
-- On landing: jumpsUsed resets to 0
```

### Per-frame setup (recommended pattern)

```lua
-- Recommended calling order every frame:
function love.update(dt)
    -- 1. Grounded detection (user's collision)
    j.grounded = collision_check(player)

    -- 2. Input handling
    if key_pressed("jump") then  j:jump()   end
    if key_released("jump") then j:release() end

    -- 3. System update
    j:update(dt)

    -- 4. Position update
    player.y = player.y + j:getVelocity() * dt
end
```
