# Spec — v0.3 Hot Reload

**Change**: v0.3-hot-reload
**Project**: Nova2D (Lua/Love2D framework)

---

## R1 — Bootstrapper module

**Requirement**: `src/hotreload.lua` MUST initialize lurker and patch `love.update`.

**Scenarios**:
- `require("src.hotreload")` runs without errors
- `love.filesystem.setRequirePath()` includes `libs/` paths
- `lurker.path` is set to `"src"`
- `lurker.interval` is set to 0.5 seconds
- `love.update` is wrapped so `lurker.update()` runs every frame before the original update

---

## R2 — Splash integration

**Requirement**: `src/states/splash.lua` MUST require the bootstrapper on its first line.

**Scenarios**:
- `require("src.hotreload")` is the first line of splash.lua
- lurker is active before the splash screen finishes
- `require` doesn't block or delay the splash timer

---

## R3 — File watching

**Requirement**: lurker MUST watch all `.lua` files under the `src/` directory recursively.

**Scenarios**:
- Changing a state file (e.g., `src/states/menu.lua`) triggers a reload
- Changing an entity file (e.g., `src/entities/player.lua`) triggers a reload
- Changing a file outside `src/` (e.g., `main.lua`, `conf.lua`, `libs/`) does NOT trigger a reload
- Creating a new file in `src/` is picked up on the next scan cycle

---

## R4 — Hotswap behavior

**Requirement**: When a file changes, lurker MUST reload the module and apply changes without crashing.

**Scenarios**:
- State is reloaded while active → state table is updated via `lume.hotswap`
- Entity is reloaded → entity module is re-required
- Syntax error in changed file → lurker's protected mode catches it, shows error, waits for fix
- File is deleted → lurker ignores the removal
- Multiple files change simultaneously → all changes are applied

---

## R5 — Performance

**Requirement**: lurker MUST NOT cause noticeable frame drops.

**Scenarios**:
- 30 `.lua` files in `src/` → polling takes < 1ms per frame
- lurker does NOT scan on frames where `dt` would be skipped (respects interval of 0.5s)
- On systems with slow disk I/O, lurker gracefully handles slow `modtime` reads

---

## Scenario Summary

| ID | Requirement | Scenarios |
|---|---|---|
| R1 | Bootstrapper module | 5 |
| R2 | Splash integration | 3 |
| R3 | File watching | 4 |
| R4 | Hotswap behavior | 5 |
| R5 | Performance | 3 |

**Total**: 5 requirements, ~20 scenarios
