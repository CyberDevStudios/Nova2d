# States

Nova2D uses **hump.gamestate** for screen management. Each screen (state) is a separate Lua module that returns a table with lifecycle callbacks.

## Lifecycle

| Callback | When it runs |
|---|---|
| `enter(previous, ...)` | When the state becomes active |
| `update(dt)` | Every frame while active |
| `draw()` | Every frame after update |
| `keyreleased(key)` | On key release (if registered) |
| `mousepressed(x, y, button)` | On mouse click |
| `leave()` | When switching away from this state |

## Built-in states

```
[Splash] ──(3s)──→ [Menu] ──(New Game)──→ [Game] ──(Esc)──→ [Pause]
                       │                      ↑                    │
                   (Credits)                   └──(Esc)────────────┘
                       │
                       ↓
                  [Credits] ←──(Esc/click)─────┘
```

### Splash
- Shows Nova2D logo (or animated title with particles when no logo found)
- Auto-transitions to Menu after 3 seconds
- Press any key to skip to Menu immediately

### Menu
- Three options: New Game, Credits, Quit
- Navigate with Up/Down arrows or mouse click
- Enter or click to select

### Game
- Empty placeholder for your game code
- Escape opens pause overlay

### Pause
- Semi-transparent overlay
- Game continues updating underneath
- Escape toggles pause on/off

### Credits
- Lists included libraries and their authors
- Escape, Enter, or mouse click returns to Menu

## Creating a new state

```lua
-- src/states/myState.lua
local MyState = {}

function MyState:enter()
    -- Initialize state variables
end

function MyState:update(dt)
    -- Game logic here
end

function MyState:draw()
    -- Render here
end

function MyState:keyreleased(key)
    if key == "escape" then
        Gamestate.switch(menu)
    end
end

return MyState
```

## State transitions

```lua
-- Switch to a state (replaces current)
Gamestate.switch(menu)

-- Push a state on top (for overlays)
Gamestate.push(pause)

-- Pop back to previous state
Gamestate.pop()
```

Use `push/pop` for overlays like pause menus. Use `switch` for normal navigation.
