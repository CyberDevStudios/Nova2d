# Love2D Input — Keyboard & Gamepad Handling

Love2D handles input through global callbacks (`love.keypressed`) and polling functions (`love.keyboard.isDown`). Nova2D goes one step further with an action-based Input system: you bind game actions like `jump` to keys and gamepad buttons, then poll actions instead of keys — with remapping, press buffering, and no event-driven spaghetti.

## The vanilla Love2D way

Discrete actions (jump, shoot) typically live in `love.keypressed`, while continuous movement polls `love.keyboard.isDown` each frame:

```lua
function love.keypressed(key, scancode, isrepeat)
    if key == "space" then
        player:jump()
    end
end

function love.update(dt)
    if love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
    end

    -- Physical layout check (works with AZERTY/QWERTY)
    if love.keyboard.isScancodeDown("w") then
        player.y = player.y - player.speed * dt
    end
end
```

Mouse input follows the same pattern with `love.mousepressed` / `love.mousereleased` and `love.mouse.isDown`. Gamepads add a third parallel API: `love.joystick` with `joystick:isGamepadDown()`.

> **Note:** `love.keyboard.isDown` takes the logical key name ("w"), which changes with keyboard layout; `love.keyboard.isScancodeDown` takes the physical position ("w" on QWERTY is "z" on AZERTY). Most games want scancodes for movement.

## The Nova2D way

Nova2D's Input system maps actions to keys once, then you poll actions in `love.update(dt)`:

```lua
local input = require("src.systems.input")

function love.load()
    inp = input.new({
        defaultBindings = {
            jump  = "space",
            left  = "left",
            right = "right",
        },
    })
end

function love.update(dt)
    if inp:isPressed("left") then
        player.x = player.x - player.speed * dt
    end

    if inp:isPressed("jump") then
        player:jump()
    end

    inp:update(dt)
end
```

Remapping is a method call, not a code change — ideal for settings menus:

```lua
inp:rebind("jump", "up", "space")   -- jump now only responds to up and space
```

Gamepad support comes free: bind Love2D's gamepad button names as keys and `isPressed()` checks both keyboard and gamepad:

```lua
inp:bind("jump", "a")               -- Xbox A / PlayStation Cross
```

Input buffering is built in — press jump 100ms before landing and `isBuffered("jump")` still catches it:

```lua
local inp = input.new({ bufferWindow = 0.1 })

function love.update(dt)
    if player.grounded and inp:isBuffered("jump") then
        player:jump()
    end
    inp:update(dt)
end
```

## Vanilla → Nova2D

| Task | Vanilla Love2D | Nova2D |
|---|---|---|
| Discrete action (jump) | Logic in `love.keypressed` | Poll `inp:isPressed("jump")` in `love.update` |
| Held key (movement) | `love.keyboard.isDown(key)` / `isScancodeDown` | `inp:isPressed("action")` — bindings handle layout |
| Mouse | `love.mousepressed` / `love.mouse.isDown` | Available via state callbacks (`mousepressed`) |
| Gamepad | `love.joystick` + `isGamepadDown` | Bind gamepad names as keys, e.g. `inp:bind("jump", "a")` |
| Remapping | Rewrite conditionals or map keys manually | `inp:rebind("jump", "space", "up")` |
| Buffering | Manual timestamps | `bufferWindow` + `inp:isBuffered("action")` |

## Next step

The Input system is a standalone module: create an instance, bind actions, poll them per frame. See the [Input System API](../api/input-system.md) for the full reference — binding management, buffer window, gamepad names, and the one rule that matters: don't put gameplay logic in `love.keypressed`.