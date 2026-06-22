# Tasks — v0.1 Base Structure + States

**Change**: v0.1-base-structure-and-states
**Project**: Nova2D (Lua/Love2D framework)
**Total files**: 15 files + 5 empty directories
**Estimated lines of code**: ~380 Lua + ~10 config
**Review forecast**: **Under 400 lines** — no chained PRs needed

---

## Milestone 1: Skeleton

### Task 1.1 — Create directory structure ✅
- **Files**: (mkdir only)
  - `src/states/`
  - `src/entities/`
  - `src/systems/`
  - `src/utils/`
  - `assets/images/`
  - `assets/sounds/`
  - `assets/fonts/`
  - `libs/hump/`
- **What**: Create all empty directories matching the plan structure
- **Completion**: `ls` shows all directories exist
- **Depends on**: nothing
- **Effort**: small

### Task 1.2 — Create conf.lua ✅
- **Files**: `conf.lua`
- **What**: Love2D window configuration. `love.conf(t)` with 800x600, resizable=true, vsync=true, title="Nova2D", version="11.0"
- **Completion**: File written with valid Lua syntax
- **Depends on**: 1.1 (directory structure)
- **Effort**: small

### Task 1.3 — Create main.lua ✅
- **Files**: `main.lua`
- **What**: Frozen entry point. Require hump.gamestate, call `Gamestate.registerEvents()`, `Gamestate.switch(require('src.states.splash'))`. ~5 lines total.
- **Completion**: File written, requires valid paths
- **Depends on**: 1.1
- **Effort**: small

### Task 1.4 — Create nova2d.lua stub ✅
- **Files**: `nova2d.lua`
- **What**: Dependency manifest stub. Returns table with name="Nova2D", version="0.1.0", author placeholder, and empty dependencies table. Ready for v0.2 gestor.
- **Completion**: File written
- **Depends on**: 1.1
- **Effort**: small

### Task 1.5 — Create nova2d-lock.lua stub ✅
- **Files**: `nova2d-lock.lua`
- **What**: Lockfile stub. Comment "generated automatically", returns empty table. Ready for v0.2 gestor.
- **Completion**: File written
- **Depends on**: 1.1
- **Effort**: small

**Milestone 1 checkpoint**: `love .` should launch a black window titled "Nova2D" at 800x600 (will crash on missing assets/states, but conf.lua works)

---

## Milestone 2: Assets & Dependencies

### Task 2.1 — Install hump gamestate ✅
- **Files**: `libs/hump/gamestate.lua`
- **What**: Download `gamestate.lua` from vrld/hump (commit 84ae1ff). Copy the raw file into libs/hump/. Only gamestate.lua needed, not the full hump repo.
- **Completion**: `libs/hump/gamestate.lua` exists with valid Lua content
- **Depends on**: 1.1
- **Effort**: small
- **Implementation note**: Use `curl` or copy from local source. The file is ~180 lines and MIT licensed.

### Task 2.2 — Create placeholder Nova2D logo ✅
- **Files**: `assets/images/logo.png`
- **What**: Create a placeholder Nova2D logo. Since we can't run Love2D to render and capture, create a simple PNG. Options:
  - Use ImageMagick: `convert -size 256x128 xc:#3498db -gravity center -pointsize 40 -fill white -annotate 0 "Nova2D" logo.png`
  - Or embed a minimal base64 PNG
- **Completion**: File exists and is loadable by Love2D
- **Depends on**: 1.1
- **Effort**: small

**Milestone 2 checkpoint**: Still crashes (no states yet) but hump path and image path are validated

---

## Milestone 3: States

### Task 3.1 — Create splash.lua ✅
- **Files**: `src/states/splash.lua`
- **What**: Splash screen state module.
  - Returns a table with `enter()`, `update(dt)`, `draw()`
  - `enter()`: load logo.png via `love.graphics.newImage()`, reset timer to 3.0
  - `update(dt)`: countdown timer. When <= 0, `Gamestate.switch(menu)`
  - `draw()`: draw logo centered, "Nova2D" text below if logo fails to load
  - NO input handling — first time is mandatory 3s
  - `pcall()` for logo loading; fallback draws text
- **Completion**: Module returns valid state table
- **Depends on**: 1.3 (main.lua requires it), 2.1 (hump), 2.2 (logo)
- **Effort**: small

### Task 3.2 — Create menu.lua ✅
- **Files**: `src/states/menu.lua`
- **What**: Main menu state module.
  - Returns table with `enter()`, `update(dt)`, `draw()`, `keyreleased(key)`, `mousepressed(x,y,button)`
  - Menu items: {"New Game", "Credits", "Quit"} as a table
  - `enter()`: reset selected index to 1
  - `draw()`: render items vertically centered, highlight selected with color
  - `keyreleased(key)`: Up/Down cycle index, Enter/Return selects
  - `mousepressed(x,y)`: detect click on item via Y-offset, select on release
  - Actions: "New Game" → `Gamestate.switch(game)`, "Credits" → `Gamestate.switch(credits)`, "Quit" → `love.event.quit()`
- **Completion**: Menu navigable by keyboard and mouse, all 3 actions work
- **Depends on**: 1.3, 2.1
- **Effort**: medium

### Task 3.3 — Create credits.lua ✅
- **Files**: `src/states/credits.lua`
- **What**: Credits screen state module.
  - Returns table with `enter()`, `draw()`, `keyreleased(key)`, `mousepressed(x,y,button)`
  - `draw()`: list libraries and their purposes: hump (gamestate), bump.lua, anim8, lurker, lovebird
  - Include "Nova2D v0.1" header
  - `keyreleased(key)`: Escape, Enter, Return, Backspace → `Gamestate.switch(menu)`
  - `mousepressed(...)`: any click → back to menu
  - Clean, readable text layout
- **Completion**: Credits scrollable/readable, returns to menu
- **Depends on**: 1.3, 2.1
- **Effort**: small

### Task 3.4 — Create game.lua ✅
- **Files**: `src/states/game.lua`
- **What**: Game placeholder state module.
  - Returns table with `enter()`, `update(dt)`, `draw()`, `keyreleased(key)`
  - `draw()`: show "Game Screen — Your game goes here" text centered
  - `keyreleased(key)`: Escape → `Gamestate.push(pause)`
  - Empty and ready for users to build upon
- **Completion**: State exists, shows placeholder text, Escape triggers pause
- **Depends on**: 1.3, 2.1
- **Effort**: small

### Task 3.5 — Create pause.lua ✅
- **Files**: `src/states/pause.lua`
- **What**: Pause overlay state module.
  - Returns table with `enter()`, `update(dt)`, `draw()`, `keyreleased(key)`
  - `draw()`: draw semi-transparent black overlay (`love.graphics.setColor(0,0,0,180)`) then "PAUSED" centered, "Esc to resume" below
  - `keyreleased(key)`: Escape → `Gamestate.pop()` (resume game)
  - Does NOT stop game update — the state below (game) continues receiving update(dt) via hump's stack
- **Completion**: Pause overlay works, Escape toggles
- **Depends on**: 1.3, 2.1
- **Effort**: small

**Milestone 3 checkpoint**: `love .` shows Splash → auto to Menu → navigate to Game → Pause with Esc → Credits → all transitions working

---

## Milestone 4: Integration

### Task 4.1 — Final wiring and verification ✅
- **Files**: verify all existing files
- **What**: 
  - Ensure all `require()` paths match actual file locations
  - Verify no circular dependencies
  - Check all `Gamestate.switch()` targets are valid modules
  - Verify pause doesn't stop game update (push/pop correct)
  - Confirm splash timer resets on re-entry
  - Test all keyboard bindings don't conflict
  - Ensure conf.lua is valid
- **Completion**: Full code review of all 15 files, all transitions verified correct
- **Depends on**: 3.1, 3.2, 3.3, 3.4, 3.5
- **Effort**: small

**Final checkpoint**: `love .` — complete Nova2D v0.1 running with all 5 states

---

## Review Workload Forecast

| Metric | Value |
|---|---|
| Total files | 15 + 5 empty dirs |
| Estimated Lua LOC | ~380 |
| Config/markup LOC | ~10 |
| Total changed lines | ~390 |
| **400-line budget** | ✅ Under budget |
| **Chained PRs needed** | No |
| **Single PR** | Yes |

This change is under 400 lines of actual code because:
- main.lua: ~5 lines
- conf.lua: ~15 lines
- Each state: 30-80 lines
- Stubs: ~5 lines each
- hump/gamestate.lua: included as-is from source (~180 lines of library code)
- Logo: binary file

**Recommendation**: Single PR. The code is modular and low-risk — all new files with zero existing code to break.

---

## File Inventory

```
nova2d/
├── main.lua                  ~5 lines    entry point (frozen)
├── conf.lua                  ~15 lines   window config
├── nova2d.lua                ~10 lines   stub dependency manifest
├── nova2d-lock.lua           ~5 lines    stub lockfile
├── src/
│   ├── states/
│   │   ├── splash.lua        ~40 lines   splash screen
│   │   ├── menu.lua          ~80 lines   main menu
│   │   ├── game.lua          ~20 lines   game placeholder
│   │   ├── pause.lua         ~35 lines   pause overlay
│   │   └── credits.lua       ~40 lines   credits screen
│   ├── entities/             (empty)
│   ├── systems/              (empty)
│   └── utils/                (empty)
├── assets/
│   ├── images/
│   │   └── logo.png          placeholder image
│   ├── sounds/               (empty)
│   └── fonts/                (empty)
└── libs/
    └── hump/
        └── gamestate.lua     ~180 lines  (vendor, vrld/hump)
```
