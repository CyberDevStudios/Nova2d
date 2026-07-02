# State Machine API

Nova2D uses **hump.gamestate** for state management (screens). The `Gamestate` object
is the only global reference in the framework and is connected to Love2D's callbacks
automatically.

## Global

### `Gamestate`
hump.gamestate module. Exposed as a global from `main.lua`. All Love2D callbacks
(`love.update`, `love.draw`, `love.keyreleased`, etc.) are redirected to the active
state automatically via `Gamestate.registerEvents()`.

### `Gamestate.registerEvents()`
Connects Love2D callbacks to the state machine. Called once in `love.load()`.
After this call, every Love2D callback is redirected to the active state (the one
at the top of the stack).

```lua
function love.load()
    Gamestate.registerEvents()
    Gamestate.switch(splash)
end
```

## Transitions

### `Gamestate.switch(state, ...)`
Replaces the current state with a new one. The previous state receives `leave()`, the new
state receives `enter(previous, ...)`.

| Parameter | Type | Description |
|---|---|---|
| `state` | table | Target state table |
| `...` | any | Optional arguments for the new state's `enter()` |

```lua
Gamestate.switch(menu)
Gamestate.switch(game, score, level)
Gamestate.switch(require("states.results"), self.score)
```

**Returns**: the previous state (the one that was replaced).

---

### `Gamestate.push(state, ...)`
Pushes a state on top of the current one (without replacing it). The current state stays
alive and receives `update(dt)` if the new state doesn't override it. Used for overlays
like pause menus.

| Parameter | Type | Description |
|---|---|---|
| `state` | table | State to push |
| `...` | any | Optional arguments for `enter()` |

```lua
Gamestate.push(pause)
```

**Returns**: the state that was at the top before the push.

---

### `Gamestate.pop()`
Pops the top state and reactivates the previous one. The popped state receives
`leave()`, the previous state does NOT receive `enter()` (it's still the same as before).

```lua
Gamestate.pop()
-- Returns to the previous state (e.g. from Pause to Game)
```

**Returns**: the popped state, or `nil` if there was nothing to pop.

---

## Query

### `Gamestate.current()`
Returns the active state (the one at the top of the stack).

```lua
local active = Gamestate.current()
```

**Returns**: table | nil — the active state, or nil if the stack is empty.

---

## Specific events

### `Gamestate.keypressed(key, scancode, isrepeat)`
### `Gamestate.keyreleased(key, scancode)`
### `Gamestate.mousepressed(x, y, button, istouch, presses)`
### `Gamestate.mousereleased(x, y, button, istouch, presses)`
### `Gamestate.update(dt)`
### `Gamestate.draw()`
### `Gamestate.resize(w, h)`

These functions delegate to the active state. There's no need to call them directly —
`registerEvents()` already wired them up. They are only used if you need manual bypass.

## State callbacks

Each state implements the callbacks it needs. All are optional.

### `enter(previous, ...)`
| Parameter | Type | Description |
|---|---|---|
| `previous` | table | The previous state (or nil if it's the first) |
| `...` | any | Arguments passed from `switch()` or `push()` |

Called when the state becomes active. Initialize variables and load resources here.

```lua
function Game:enter(previous, levelName)
    self.level = levelName
    self.score = 0
    self.player = {}
    Player:enter(self.player)
end
```

### `leave()`
Called when the state stops being active (via `switch()` or `pop()`). Use it to
clean up resources.

```lua
function Game:leave()
    self.player = nil
end
```

### `update(dt)`
Called every frame. All game logic goes here.

| Parameter | Type | Description |
|---|---|---|
| `dt` | number | Delta time in seconds (frame-independent) |

### `draw()`
Called every frame after `update()`. All rendering goes here.

### `keyreleased(key, scancode)`
### `keypressed(key, scancode, isrepeat)`
Called when a key is pressed/released. Prefer `keyreleased` for discrete
actions (jump, shoot) to avoid repetition.

| Parameter | Type | Description |
|---|---|---|
| `key` | string | Key name (e.g. "escape", "return", "space") |
| `scancode` | string | Physical key code (layout-independent) |

### `mousepressed(x, y, button, istouch, presses)`
### `mousereleased(x, y, button, istouch, presses)`

| Parameter | Type | Description |
|---|---|---|
| `x`, `y` | number | Click coordinates |
| `button` | number | 1 = left, 2 = right, 3 = middle |
| `istouch` | boolean | true if the event comes from a touch input |
| `presses` | number | Click counter (for double-click) |

### `resize(w, h)`
Called when the window is resized (requires `t.window.resizable = true` in
`conf.lua`).

```lua
function Game:resize(w, h)
    self.screenW = w
    self.screenH = h
end
```

## State stack

The state stack can have multiple levels thanks to `push`/`pop`. This is used
mainly for overlays:

```
Top:     [Pause]      ← Gamestate.push(pause)
         [Game]       ← Base state
Bottom:  [Menu]       ← Previous states (if switch wasn't used)
```

- `current()` returns the top (Pause in this case)
- `update(dt)` delegates to the top, but if Pause explicitly calls
  `self.previous:update(dt)` (as the default pause does), Game keeps running
  below
- `draw()` only shows the top — if you want to see what's below, the top must draw it
  transparent
