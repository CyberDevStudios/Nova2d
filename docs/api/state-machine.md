# State Machine API

Nova2D uses hump.gamestate for state management. The `Gamestate` object is the only global reference in the framework.

## Global

### `Gamestate`
The hump.gamestate module. Wired into Love2D callbacks via `Gamestate.registerEvents()` in `main.lua`.

## Functions

### `Gamestate.switch(state, ...)`
Switch to a new state, replacing the current one.
- `state`: a state table
- `...`: arguments passed to the state's `enter()`

```lua
Gamestate.switch(menu)
Gamestate.switch(game, "level1", difficulty)
```

### `Gamestate.push(state, ...)`
Push a state on top of the current one (for overlays).
- `state`: a state table
- `...`: arguments passed to the state's `enter()`

```lua
Gamestate.push(pause)
```

### `Gamestate.pop()`
Pop the top state and resume the previous one.

```lua
Gamestate.pop()  -- Resume game from pause
```

## State callbacks

| Callback | Description |
|---|---|
| `enter(previous, ...)` | Called when the state becomes active |
| `update(dt)` | Per-frame logic |
| `draw()` | Per-frame rendering |
| `keyreleased(key)` | Key release events |
| `mousepressed(x, y, button)` | Mouse click events |
| `leave()` | Called when switching away |
