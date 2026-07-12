# Health System

A standalone module for **HP tracking, damage, healing, invincibility frames, and death state** — no external dependencies. You provide the game logic (when to damage, when to heal), the system handles clamping, state transitions, event firing, and i-frame timing.

```lua
local health = require("src.systems.health")

-- Create with default config
local h = health.new()
```

## Quick start

```lua
local health = require("src.systems.health")

function love.load()
    h = health.new({ maxHp = 100, iFrameDuration = 0.5 })
end

function love.update(dt)
    -- Tick i-frame timer
    h:update(dt)

    -- Example: take damage on collision
    if colliding_with_enemy() then
        local applied = h:takeDamage(25, "slash")
        if applied then
            flash_screen_red()     -- visual feedback
            print("Ouch! HP:", h:getCurrentHp())
        end
    end

    -- Example: heal on pickup
    if picking_up_potion() then
        h:heal(50)
    end
end

function love.draw()
    -- Draw a simple health bar
    local barWidth = 200
    local ratio = h:getCurrentHp() / h:getMaxHp()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 10, 10, barWidth * ratio, 20)
end
```

## Config

### `health.new(config)`

All fields are optional. Pass only what you want to override.

| Field | Type | Default | Description |
|---|---|---|---|
| `maxHp` | number | `100` | Maximum hit points |
| `iFrameDuration` | number | `1.0` | Invincibility duration after taking damage (seconds) |

```lua
-- Glass cannon: low HP, short i-frames
local h = health.new({
    maxHp = 50,
    iFrameDuration = 0.25,
})

-- Immortal: huge HP, long i-frames
local boss = health.new({
    maxHp = 5000,
    iFrameDuration = 2.0,
})
```

## API

### `health:update(dt)`

Core update. Call once per frame to tick the i-frame timer. When the timer expires, the state transitions back to `alive` and `iFramesEnd` fires.

```lua
function love.update(dt)
    h:update(dt)
end
```

### `health:takeDamage(amount, type)`

Apply damage to the entity. The `type` parameter is a string tag (e.g. `"slash"`, `"fire"`, `"fall"`) that event listeners can use to filter damage sources.

**Returns**:
- `true` — damage was applied (HP reduced, events fired)
- `false` — damage was blocked (dead or invincible)

```lua
if h:takeDamage(25, "slash") then
    play_sound("hit")
end
```

**Behavior by state**:

| State | Result |
|---|---|
| `alive` | HP reduced, `damaged` event fires. If HP reaches 0 → `died`. Otherwise → `invincible`, `iFramesStart`. |
| `invincible` | Blocked — no HP change, no events. |
| `dead` | Blocked — no HP change, no events. |

### `health:heal(amount)`

Restore HP, clamped to `maxHp`. No-op when dead.

**Returns**:
- `true` — health was restored
- `false` — blocked (entity is dead)

```lua
h:heal(50)
```

### `health:reset()`

Restores HP to `maxHp`, clears all states back to `alive`, resets i-frame timer.

**Returns**: `self` (for chaining).

```lua
-- Respawn: full reset
h:reset()
```

### `health:on(event, cb)`

Register an event listener. Returns the callback (useful for `table.remove()` to unregister later).

| Event | Payload | Fires when |
|---|---|---|
| `damaged` | `amount, type` | Damage is applied (HP reduced) |
| `healed` | `amount` | HP is restored by `heal()` |
| `died` | — | HP reaches 0 |
| `iFramesStart` | — | Invincibility period begins (after damage) |
| `iFramesEnd` | — | Invincibility period ends |

```lua
h:on("damaged", function(amount, type)
    print("Took", amount, "damage from", type)
    play_sound("hurt")
end)

h:on("healed", function(amount)
    print("Healed for", amount)
    play_sound("heal")
end)

h:on("died", function()
    print("Player died!")
    trigger_death_animation()
end)

h:on("iFramesStart", function()
    print("Invincible!")
    start_blinking()
end)

h:on("iFramesEnd", function()
    print("Vulnerable again")
    stop_blinking()
end)
```

### Getters

| Method | Returns | Description |
|---|---|---|
| `:getCurrentHp()` | number | Current HP |
| `:getMaxHp()` | number | Maximum HP (from config) |
| `:isDead()` | boolean | `true` when HP is 0, all operations locked |
| `:isInvincible()` | boolean | `true` while i-frames are active |
| `:getIFramesRemaining()` | number | Seconds of invincibility remaining (0 = not invincible) |

## State machine

The system tracks three internal states:

```
┌────────┐  takeDamage()   ┌────────────┐  iFrame expires  ┌────────┐
│  alive  │ ──────────────→ │ invincible  │ ──────────────→ │  alive  │
│ (idle)  │                 │  (i-frames) │                  │ (idle)  │
└────────┘                  └────────────┘                  └────────┘
     │                                                            ↑
     │ takeDamage() → hp=0                                       │
     ▼                                                            │
  ┌──────┐                                                       │
  │ dead │ ────────────────── reset() ───────────────────────────┘
  └──────┘
```

- **alive** — normal state, can take damage and heal
- **invincible** — entered automatically after taking damage; i-frame timer counts down; all damage blocked
- **dead** — HP is 0, all operations locked; can only be exited via `reset()`

## Examples

### Damage and i-frames

```lua
local h = health.new({ maxHp = 100, iFrameDuration = 0.5 })

h:on("damaged", function(amount, type)
    print("Took " .. amount .. " " .. type .. " damage")
end)

h:on("iFramesStart", function()
    print("Invincible for " .. h:getIFramesRemaining() .. "s")
end)

h:on("iFramesEnd", function()
    print("Now vulnerable")
end)

h:takeDamage(30, "slash")  -- HP: 100 → 70, i-frames start
h:takeDamage(40, "fire")   -- blocked (invincible), HP still 70
-- ... 0.5s later (i-frames end via update)
h:takeDamage(40, "fire")   -- HP: 70 → 30, i-frames start again
```

### Damage type filtering

The `type` string lets listeners react differently per damage source:

```lua
h:on("damaged", function(amount, type)
    if type == "fire" then
        play_sound("burn")
    elseif type == "slash" then
        spawn_blood_particles()
    end
end)

-- Different damage sources
h:takeDamage(15, "slash")
h:takeDamage(8, "fire")
```

### Full death → reset cycle

```lua
local h = health.new({ maxHp = 100 })

h:on("died", function()
    print("Game over!")
    -- Show death screen, wait for input, then:
    love.timer.after(2, function()
        h:reset()
        print("Respawned with", h:getCurrentHp(), "HP")
    end)
end)

h:takeDamage(100, "fatal")  -- HP: 100 → 0, "died" fires
h:heal(50)                  -- blocked (dead)
h:takeDamage(10, "slash")  -- blocked (dead)
-- ... after reset():
-- HP back to 100, state back to "alive"
```

### iFrameDuration = 0 (no invincibility)

```lua
local h = health.new({ iFrameDuration = 0 })

h:takeDamage(20, "slash")  -- HP: 100 → 80
h:takeDamage(20, "slash")  -- HP: 80 → 60 (no i-frames to block)
-- Each hit registers because invincibility is disabled
```

## Per-frame setup (recommended pattern)

```lua
function love.update(dt)
    -- 1. Tick i-frame timer
    h:update(dt)

    -- 2. Check for damage sources
    if colliding_with_enemy() then
        h:takeDamage(25, "contact")
    end

    -- 3. Check for healing
    if picking_up_potion() then
        h:heal(50)
    end
end
```
