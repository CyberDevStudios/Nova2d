# Input System

A standalone action-based input system that maps game actions (like `jump`, `left`, `action`) to keys and gamepad buttons. Supports **binding remapping**, **press buffering**, and **per-frame polling** — no event-driven spaghetti.

```lua
local input = require("src.systems.input")

-- Create with default bindings
local inp = input.new()
```

## Quick start

```lua
local input = require("src.systems.input")

function love.load()
    inp = input.new({
        defaultBindings = {
            jump   = "space",
            attack = "x",
        },
    })
end

function love.update(dt)
    -- Poll actions each frame (no love.keypressed needed)
    if inp:isPressed("jump") then
        player:jump()
    end

    if inp:isPressed("attack") then
        player:attack()
    end

    -- Trim expired buffer entries
    inp:update(dt)
end
```

## Config

### `input.new(config)`

All fields are optional. Pass only what you want to override.

| Field | Type | Default | Description |
|---|---|---|---|
| `bufferWindow` | number | `0` | Buffer window in seconds (`0` = disabled) |
| `defaultBindings` | table | _see below_ | Action-to-key mapping |

**Default bindings** (used when no `defaultBindings` is provided):

| Action | Key |
|---|---|
| `jump` | `space` |
| `left` | `left` |
| `right` | `right` |
| `up` | `up` |
| `down` | `down` |
| `action` | `x` |
| `cancel` | `z` |
| `start` | `return` |

```lua
-- WASD + gamepad-only config
local inp = input.new({
    bufferWindow = 0.15,
    defaultBindings = {
        jump   = "w",
        left   = "a",
        right  = "d",
        down   = "s",
        action = "e",
    },
})
```

## API

### `input:bind(action, ...keys)`

Add one or more keys to an action. Existing bindings are preserved. Duplicates are silently ignored.

```lua
inp:bind("jump", "up", "w", "gp:facebottom")   -- jump now responds to up, w, or gamepad A
```

### `input:unbind(action, key)`

Remove a specific key from an action. If `key` is omitted, **all** bindings for the action are removed.

```lua
inp:unbind("jump", "up")    -- remove only "up"
inp:unbind("jump")          -- remove ALL jump bindings
```

### `input:rebind(action, ...keys)`

Replace **all** existing bindings for an action with the given keys. Any previous bindings are discarded.

```lua
inp:rebind("jump", "w", "space")   -- jump now only responds to w and space
```

### `input:update(dt)`

Trim expired buffer entries. Call **once per frame**. Safe to call even when `bufferWindow` is `0` (no-op).

```lua
function love.update(dt)
    inp:update(dt)
end
```

### `input:isPressed(action)`

Check whether any key bound to an action is **currently held down**. Checks both keyboard and gamepad (when `love.joystick` is available).

```lua
if inp:isPressed("left") then
    player.x = player.x - speed * dt
end
```

### `input:isReleased(action)`

Inverse of `isPressed`. Returns `true` when **no** bound key is held.

```lua
if inp:isReleased("jump") then
    -- player released all jump keys
end
```

### `input:isBuffered(action)`

Check whether a key bound to an action was **pressed within the buffer window**. Useful for tight input timing (e.g., buffering an attack before it's available).

Only meaningful when `bufferWindow > 0` in config.

```lua
if inp:isBuffered("attack") then
    -- player pressed attack within the window
end
```

### `input:getPressedActions()`

Return a list of action names that are currently pressed. Useful for debug overlays or menu navigation.

```lua
local active = inp:getPressedActions()
for _, action in ipairs(active) do
    print("Currently pressing:", action)
end
```

### `input:getBindings(action)`

Return a copy of the keys bound to an action. Returns `nil` if the action has no bindings.

```lua
local keys = inp:getBindings("jump")
-- e.g., { "space", "up" }
```

### `input:reset()`

Clear **all** bindings and **all** buffer state. The instance becomes empty — no actions respond until you call `bind()` again.

**Returns**: `self` (for chaining).

```lua
inp:reset()
inp:bind("jump", "space")   -- rebind from scratch
```

## Buffer window

The buffer window lets you accept inputs that happened slightly **before** the game was ready to process them. This makes controls feel more responsive.

```lua
local inp = input.new({ bufferWindow = 0.1 })
```

When a bound key is pressed, its timestamp is stored. `isBuffered(action)` returns `true` for `bufferWindow` seconds after that press. `update(dt)` cleans up expired entries each frame.

**Typical use case**: buffering a jump input before the player lands:

```lua
function love.update(dt)
    -- Player pressed jump 50ms before landing.
    -- isBuffered("jump") will return true when we check post-landing.
    if player.grounded and inp:isBuffered("jump") then
        player:jump()
    end

    inp:update(dt)
end
```

## Remapping example

Let players customize their controls at runtime:

```lua
-- Settings menu: rebind the "jump" action
inp:rebind("jump", selected_key)

-- Later, check the current binding for display
local jumpKeys = inp:getBindings("jump")
print("Jump is bound to:", table.concat(jumpKeys, ", "))
```

Multi-key support per action makes it easy to support both keyboard and gamepad simultaneously:

```lua
inp:rebind("jump", "space", "up", "gp:facebottom")
```

## Gamepad support

When `love.joystick` is enabled in `conf.lua`, `isPressed()` also checks connected gamepads. No extra setup needed — pass gamepad button names (matching Love2D's `isGamepadDown` strings) as keys:

```lua
inp:bind("jump", "gp:facebottom")   -- PlayStation X / Xbox A
```

If `love.joystick` is disabled or no gamepad is connected, the gamepad check is silently skipped.

## ⚠️ Important: Do NOT use love.keypressed / love.keyreleased

This system **internally hooks** `love.keypressed` and `love.keyreleased` to capture press timestamps for the buffer. Your `love.keypressed` and `love.keyreleased` callbacks are still called (the system chains to them automatically), but:

- **Do NOT put core gameplay input logic** in `love.keypressed`. Use `isPressed()` / `isBuffered()` in `love.update()` instead.
- **Do NOT overwrite** `love.keypressed` after calling `input.new()`.
- If you need `love.keypressed` for non-input purposes (e.g., toggling fullscreen), define it **before** calling `input.new()` — the system will chain to it.

```lua
-- ❌ Wrong: gameplay logic in love.keypressed
function love.keypressed(key)
    if key == "space" then player:jump() end
end

-- ✅ Right: poll in love.update
function love.update(dt)
    if inp:isPressed("jump") then player:jump() end
    inp:update(dt)
end
```

## Keyboard + gamepad key names

Any string accepted by `love.keyboard.isDown` (keyboard) or `love.joystick:isGamepadDown` (gamepad) can be used in bindings. Common examples:

| Type | Keys |
|---|---|
| Keyboard | `"space"`, `"left"`, `"right"`, `"up"`, `"down"`, `"return"`, `"x"`, `"z"`, `"a"`–`"z"` |
| Gamepad | `"gp:facebottom"` (A / X), `"gp:faceright"` (B / Circle), `"gp:faceleft"` (X / Square), `"gp:gatop"` (Y / Triangle), `"gp:leftshoulder"`, `"gp:rightshoulder"` |
