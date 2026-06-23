# Design — v0.3 Hot Reload

**Change**: v0.3-hot-reload
**Project**: Nova2D (Lua/Love2D framework)

---

## 1. Architecture

### Module dependency

```
splash.lua
  └── require("src.hotreload")
        └── require("lurker")      ← from libs/lurker/
              └── lume              ← bundled with lurker
```

### Callback chain

```
Before hotreload:
love.update → Gamestate dispatcher → state:update(dt)

After hotreload:
love.update → lurker.update() → lurker.scan() [if interval passed]
           → original love.update → Gamestate → state:update(dt)
```

Lurker's `initwrappers()` runs on first `lurker.update()` call and wraps `love.*` callbacks in `xpcall`. This happens AFTER `Gamestate.registerEvents()` has already wrapped them from `main.lua`.

The wrapper nesting at runtime:
1. `love.update` → set by Love2D
2. Lurker wraps it with xpcall → `lurker.update()` first, then original
3. Original is Gamestate's dispatch → calls active state's `update(dt)`

## 2. File design

### src/hotreload.lua (~20 lines)

```lua
-- Hot reload bootstrapper for lurker
-- Called once from splash.lua. Does NOT modify main.lua.

-- Extend require path to include libs/
love.filesystem.setRequirePath(
    "?.lua;?/init.lua;libs/?.lua;libs/?/init.lua"
)

local lurker = require("lurker")
lurker.path = "src"
lurker.interval = 0.5

lurker.postswap = function(name)
    print("[HOTRELOAD] " .. name .. " reloaded")
end

-- Patch love.update to include lurker polling
local original_update = love.update
love.update = function(dt)
    lurker.update()
    original_update(dt)
end
```

### src/states/splash.lua (1 line addition)

At the very top of the file, before any other code:

```lua
require("src.hotreload")
-- existing splash code...
```

## 3. Require path resolution

Lurker lives at `libs/lurker/` after installation. Love2D's default `package.path` includes `?.lua` and `?/init.lua` relative to the game directory, but NOT `libs/?.lua`.

The `love.filesystem.setRequirePath()` call in the bootstrapper adds `libs/?.lua` and `libs/?/init.lua` so `require("lurker")` resolves correctly.

## 4. lurker configuration

| Setting | Value | Rationale |
|---|---|---|
| `path` | `"src"` | Watch all game source code |
| `interval` | `0.5` | 500ms between scans — balances reactivity and CPU |
| `postswap` | print message | Visual feedback in console |
| `protected` | `true` | Default — catches errors without crashing |

## 5. Edge cases

### State reloaded while active
Lurker uses `lume.hotswap()` which does a recursive table merge. Since hump.gamestate stores state tables by reference and the references don't change, the active state's new methods are picked up immediately without needing to re-enter the state.

### Syntax error in file
Lurker's protected mode catches the error, displays a red error screen (built-in), and continues polling. When the file is fixed and saved, lurker automatically resumes normal operation. No restart needed.

### Module-level variables reset
Variables declared at module level (like `logo` or `timer` in `splash.lua`) reset when the file is reloaded. This is by design — mutable state should live in `enter()`.

### Dependencies that reference the old module
If module A requires module B, and B is reloaded, A still holds a reference to the old B. This is a known limiter of Lua's module system and lurker's docs acknowledge this. Mitigation: keep modules stateless or reload dependent modules too.

## 6. Architecture decisions

| AD | Decision | Rationale |
|---|---|---|
| AD-1 | Bootstrapper in splash.lua, not main.lua | Frozen main.lua contract maintained |
| AD-2 | lurker.path = "src" | Only watch game code, not libs or config |
| AD-3 | libs/ added to require path | Required for lurker module resolution |
| AD-4 | postswap with print | Simple console feedback without UI |
| AD-5 | 0.5s scan interval | Good balance for development reactivity |
