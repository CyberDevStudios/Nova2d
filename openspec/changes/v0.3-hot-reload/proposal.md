# Proposal — v0.3 Hot Reload

**Change**: v0.3-hot-reload
**Project**: Nova2D (Lua/Love2D framework)

---

## Intent

Add hot reload support via lurker so developers can edit source files and see changes instantly without restarting the game.

---

## Scope

### IN

| Element | Description |
|---|---|
| `src/hotreload.lua` | Bootstrapper module: sets require path, configures lurker, patches love.update |
| `src/states/splash.lua` | One-line addition: `require("src.hotreload")` |
| lurker dependency | Already declared in nova2d.lua, installable via `love gestor/ install` |
| File watch path | `src/` directory (recursive) — states, entities, systems, utils |

### OUT

| Element | Reason |
|---|---|
| Modify `main.lua` | Frozen contract maintained |
| Modify `conf.lua` | Not needed |
| Watch `libs/` | External deps shouldn't be hot-reloaded |
| Watch `main.lua` or `conf.lua` | Require full restart |
| Custom error UI | Lurker's built-in error screen is sufficient |

---

## Approach

### Architecture

```
love.update(dt)
  └── lurker.update()     ← polls files, hotswaps changed modules
  └── Gamestate.update()  ← routes to active state
```

Lurker's lazy init wraps `love.*` callbacks on first `update()` call. By then, `Gamestate.registerEvents()` has already set them up. The wrapper chain:

```
love.update → lurker's xpcall → Gamestate dispatcher → state:update(dt)
```

### src/hotreload.lua

```lua
-- Ensure libs/ is on the require path
love.filesystem.setRequirePath("?.lua;?/init.lua;libs/?.lua;libs/?/init.lua")

local lurker = require("lurker")
lurker.path = "src"
lurker.interval = 0.5
lurker.postswap = function(name)
    print("[HOTRELOAD] " .. name .. " reloaded")
end

-- Patch love.update to add lurker scanning
local original_update = love.update
function love.update(dt)
    lurker.update()
    original_update(dt)
end
```

---

## Files affected

| File | Action | Lines |
|---|---|---|
| `src/hotreload.lua` | Create | ~20 |
| `src/states/splash.lua` | Modify (+1 line) | +1 |
| **Total** | | **~21 lines** |

---

## Complexity

**Low**. Two files, ~21 lines, well-understood library, no architecture changes.

## Risk

None. Lurker is stable, well-tested, and the integration is minimal. The frozen main.lua contract is respected.
