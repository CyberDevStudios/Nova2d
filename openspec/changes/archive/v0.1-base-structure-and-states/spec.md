# v0.1 — Base Structure and States: Specification

> **Status**: Full spec (new domain, no prior specs)
> **Applies to**: Nova2D framework skeleton — directory tree, entry points, game states, and assets

---

## 1. File Specifications

### 1.1 `main.lua` — Entry Point

| Field | Value |
|-------|-------|
| **Purpose** | Love2D entry point, wires hump.gamestate and all 5 states |
| **Dependencies** | `libs/hump/gamestate.lua`, `src/states/splash.lua`, `menu.lua`, `game.lua`, `pause.lua`, `credits.lua` |
| **Exports** | None — Love2D calls `love.load()`, `love.update(dt)`, `love.draw()` |
| **Behaviors** | `love.load()`: `Gamestate.registerEvents()`, `Gamestate.switch(states.splash)`. `love.update(dt)`: `Gamestate.update(dt)`. `love.draw()`: `Gamestate.draw()`. Marked `-- no tocar` — users MUST NOT modify this file. |
| **Edge cases** | Missing hump module → Lua `require` error crashes at startup. Missing state module → same. |

### 1.2 `conf.lua` — Window Configuration

| Field | Value |
|-------|-------|
| **Purpose** | Love2D window configuration |
| **Dependencies** | None |
| **Exports** | `love.conf(t)` function |
| **Behaviors** | `t.window.width = 800`, `t.window.height = 600`, `t.window.resizable = true`, `t.window.vsync = true`, `t.window.title = "Nova2D"`, `t.console = false` |
| **Edge cases** | None — Love2D applies defaults for any omitted field. |

### 1.3 `nova2d.lua` — Dependency Manifest Stub

| Field | Value |
|-------|-------|
| **Purpose** | Stub manifest for the v0.2 dependency manager |
| **Dependencies** | None |
| **Exports** | Lua table with `{name, version, author, dependencies = {}}` |
| **Behaviors** | Returns a table. `name` = project name (default `"my-game"`). `version` = `"0.1.0"`. `author` = placeholder. `dependencies` = empty table `{}`. |
| **Edge cases** | Not loaded by current code — purely declarative for v0.2. |

### 1.4 `nova2d-lock.lua` — Lockfile Stub

| Field | Value |
|-------|-------|
| **Purpose** | Stub lockfile for the v0.2 dependency manager |
| **Dependencies** | None |
| **Exports** | Lua table `{}` |
| **Behaviors** | Top comment reads: `-- Archivo generado automáticamente. No editar a mano.`. Returns empty table `{}`. |
| **Edge cases** | Not loaded by current code — purely declarative for v0.2. |

### 1.5 `src/states/splash.lua` — Splash Screen

| Field | Value |
|-------|-------|
| **Purpose** | Displays Nova2D logo, waits 3 seconds, auto-transitions to Menu |
| **Dependencies** | `hump.gamestate`, `assets/images/logo.png` (optional) |
| **Exports** | State table: `enter(h, prev)`, `update(dt)`, `draw()` |
| **Behaviors** | `enter()`: load `logo.png` via `love.graphics.newImage()`, reset `timer = 0`. `update(dt)`: increment timer, if `timer >= 3.0` → `Gamestate.switch(menu)`. `draw()`: clear screen, draw logo centered (or fallback text), draw "Nova2D v0.1" below. |
| **Edge cases** | Logo not found → draw centered "Nova2D" in Love2D default font (24pt). `dt = 0` on frame 1 → timer still advances, transition works normally. Timer drift: accumulate dt, compare >= 3.0 (not ==). |

### 1.6 `src/states/menu.lua` — Main Menu

| Field | Value |
|-------|-------|
| **Purpose** | Main menu with 3 selectable options |
| **Dependencies** | `hump.gamestate` |
| **Exports** | State table: `enter(h, prev)`, `update(dt)`, `draw()`, `keypressed(k)`, `mousepressed(x, y, btn)` |
| **Behaviors** | Options: `["New Game", "Credits", "Quit"]`. `enter()`: reset `selected = 1`. `draw()`: render title "Nova2D" + menu items with highlight on `selected`. `keypressed(k)`: Up/Down cycle `selected` (wrap 1..3), Enter → dispatch. `mousepressed(x, y, btn)`: hit-test items by bounding box, select on click. `Quit` → `love.event.quit()`. |
| **Edge cases** | Rapid Enter → hump queues transitions; no race. Click outside items → no-op. Click on selectable area → triggers action. Window resize → redraw items, re-compute hit boxes. |

### 1.7 `src/states/game.lua` — Game Placeholder

| Field | Value |
|-------|-------|
| **Purpose** | Empty placeholder screen — user builds game here |
| **Dependencies** | `hump.gamestate` |
| **Exports** | State table: `enter(h, prev)`, `update(dt)`, `draw()`, `keypressed(k)` |
| **Behaviors** | `draw()`: render centered "Game Screen — placeholder" text. `keypressed(k)`: Escape → `Gamestate.push(pause)`. `enter()`: reset any future game state. |
| **Edge cases** | Escape pressed while no pause exists → safe (pause module always loaded). |

### 1.8 `src/states/pause.lua` — Pause Overlay

| Field | Value |
|-------|-------|
| **Purpose** | Pause overlay pushed on top of Game — game updates continue underneath |
| **Dependencies** | `hump.gamestate`, reference to Game state for update propagation |
| **Exports** | State table: `enter(h, prev)`, `update(dt)`, `draw()`, `keypressed(k)` |
| **Behaviors** | `update(dt)`: MUST propagate `dt` to the underlying Game state so game logic continues. `draw()`: draw semi-transparent overlay (`love.graphics.setColor(0,0,0,128)`) over full screen, then "PAUSED" text centered. `keypressed(k)`: Escape → `Gamestate.pop()`. |
| **Edge cases** | `Gamestate.pop()` on single-entry stack → no-op (hump guards internally). Fast double Escape → second pop is safe (hump queues). Underlying state nil → gracefully skip update propagation, draw overlay only. |

### 1.9 `src/states/credits.lua` — Credits Screen

| Field | Value |
|-------|-------|
| **Purpose** | Displays Nova2D framework credits and library licenses |
| **Dependencies** | `hump.gamestate` |
| **Exports** | State table: `enter(h, prev)`, `update(dt)`, `draw()`, `keypressed(k)`, `mousepressed(x, y, btn)` |
| **Behaviors** | `draw()`: render "Nova2D" title, list libraries (`hump.gamestate`), thank-you message, and return instructions. `keypressed(k)`: Escape, Enter, Backspace, Return all → `Gamestate.switch(menu)`. `mousepressed(x, y, btn)`: any click → `Gamestate.switch(menu)`. |
| **Edge cases** | Multiple keys pressed simultaneously → first registered wins, target is idempotent (switch to menu). |

### 1.10 `assets/images/logo.png` — Placeholder Logo

| Field | Value |
|-------|-------|
| **Purpose** | Nova2D brand logo displayed on Splash screen |
| **Dependencies** | None (loaded by splash.lua via `love.graphics.newImage`) |
| **Format** | PNG, RGBA, 256×256 minimum |
| **Behaviors** | Loaded on Splash `enter()`. Drawn centered via `love.graphics.draw(logo, x, y, 0, scale, scale)`. |
| **Edge cases** | Missing or corrupt → splash falls back to text. See Section 5. |

### 1.11 `libs/hump/gamestate.lua` — External Dependenc

| Field | Value |
|-------|-------|
| **Purpose** | State machine library by vrld/hump. Only `gamestate.lua` is required for v0.1. |
| **Integration** | Copied manually from upstream (no package manager yet). Not authored by this project. |
| **API used** | `Gamestate.new()`, `Gamestate.registerEvents()`, `Gamestate.switch(state)`, `Gamestate.push(state)`, `Gamestate.pop()`, `Gamestate.update(dt)`, `Gamestate.draw()`, `Gamestate.keypressed(k)`, `Gamestate.mousepressed(x,y,btn)` |
| **Edge cases** | Missing file → `require("libs.hump.gamestate")` errors in `main.lua` → game won't start. This is a hard failure. |

---

## 2. State Transitions

| From | To | Trigger | Pre-condition | Post-condition |
|------|----|---------|---------------|----------------|
| Splash | Menu | 3s timer elapses | Logo displayed, timer ≥ 3.0 | `Gamestate.switch(menu)`, menu enters with selection=1 |
| Menu | Game | "New Game" selected (Enter/click) | Menu visible, item selected | `Gamestate.switch(game)`, game state enters |
| Menu | Credits | "Credits" selected (Enter/click) | Menu visible, item selected | `Gamestate.switch(credits)`, credits enter, library list shown |
| Menu | Exit | "Quit" selected (Enter/click) | Menu visible, item selected | `love.event.quit()` called |
| Game | Pause | Escape pressed | Game state active | `Gamestate.push(pause)`, overlay shown, game updates continue |
| Pause | Game | Escape pressed | Pause overlay active | `Gamestate.pop()`, overlay removed, game resumes visual rendering |
| Credits | Menu | Escape / Enter / Backspace / click | Credits visible | `Gamestate.switch(menu)`, menu enters with fresh selection |

### Transition Rules

1. Splash→Menu MUST be automatic (no user input required).
2. Splash MUST NOT be skippable in v0.1 (3s minimum, no key/click to skip).
3. Game↔Pause MUST use `gs.push()`/`gs.pop()` (stack-based) to preserve Game state.
4. All other transitions MUST use `gs.switch()` (replacement).
5. Multiple rapid inputs MUST NOT cause state corruption — hump.gamestate's transition queue handles ordering.

---

## 3. Navigation Specifications

### R1: Menu Keyboard Navigation

The Menu state MUST support keyboard navigation with Up/Down/Enter.

| Scenario | Steps | Expected |
|----------|-------|----------|
| Navigate down | Press Down on selection 1 ("New Game") | Selection moves to 2 ("Credits") |
| Navigate up | Press Up on selection 1 ("New Game") | Wraps to 3 ("Quit") |
| Select item | Press Enter on selection 1 | Transitions to Game state |
| Select Quit | Press Enter on selection 3 | `love.event.quit()` called |

### R2: Menu Mouse Navigation

The Menu state MUST support mouse clicks for item selection.

| Scenario | Steps | Expected |
|----------|-------|----------|
| Click on item | Click on "New Game" bounding box | Transitions to Game state |
| Click outside items | Click on empty background area | No action, menu stays visible |

### R3: Pause Escape Toggle

| Scenario | Steps | Expected |
|----------|-------|----------|
| Pause game | Press Escape while in Game | Pause overlay shown, game updates continue |
| Resume game | Press Escape while in Pause | Overlay removed, game visible again |

### R4: Credits Return Navigation

| Scenario | Steps | Expected |
|----------|-------|----------|
| Return via keyboard | Press Escape / Enter / Backspace while in Credits | Returns to Menu |
| Return via mouse | Click anywhere while in Credits | Returns to Menu |

### R5: Splash Non-skippable

| Scenario | Steps | Expected |
|----------|-------|----------|
| Attempt skip | Press any key during Splash (first 3s) | No effect, Splash continues |
| Auto-transition | Wait 3 seconds | Automatically transitions to Menu |

---

## 4. Placeholder Logo Specification

### Visual Description

- **Shape**: A stylized supernova/star burst — a central circle with 8 radiating triangular rays at 45° angles
- **Colors**: Gradient from bright cyan (`#00D4FF`) in the center to deep purple (`#7B2D8E`) at the ray tips
- **Text**: "Nova2D" set in a bold sans-serif font (Arial/Helvetica or Love2D default), centered below the icon
- **Dimensions**: 256×256 pixels minimum, PNG RGBA format
- **Background**: Transparent (alpha channel)

### Generation

For v0.1, the logo SHOULD be generated programmatically using ImageMagick or similar tool to avoid requiring a designer. A simple geometric star on a transparent background with the text is sufficient.

### Fallback

If the PNG cannot be loaded, the Splash state MUST display centered text "Nova2D" using Love2D's default font at 36pt as a fallback. The 3s timer and transition MUST proceed regardless.

---

## 5. Error Handling Specifications

| Error | Symptom | Behavior | Acceptable? |
|-------|---------|----------|-------------|
| `logo.png` missing/corrupt | `love.graphics.newImage("assets/images/logo.png")` returns nil or errors | Fallback: render centered "Nova2D" text. Timer still counts. Transition proceeds. | Yes — graceful degradation |
| `hump/gamestate.lua` not found | `require("libs.hump.gamestate")` throws error | Love2D crash with Lua error message: module not found. | Yes — hard failure is correct; framework cannot run |
| State module missing (e.g., `menu.lua`) | `require("src.states.menu")` throws error | Love2D crash at startup. | Yes — hard failure on missing code |
| Rapid key presses during transition | Multiple inputs queue in hump | hump.gamestate handles queue internally. No crash, no state corruption. | Yes — framework handles gracefully |
| Button 1 pressed during Splash | `keypressed` not registered on splash | No-op — Splash ignores all input. | Yes — by design, Splash is non-skippable |

### Error Handling Rules

1. Asset failures (logo) MUST degrade gracefully — show fallback text, never crash.
2. Module failures (hump, states) MUST crash with a clear Lua error — missing code is not recoverable.
3. Input race conditions MUST NOT corrupt the state machine — hump's queue provides safety.
4. The framework MUST NOT suppress errors silently — any unexpected error propagates to Love2D's error handler.

---

## 6. Naming Conventions

| Category | Convention | Examples | Notes |
|----------|------------|----------|-------|
| Variables & functions | `camelCase` | `selectedItem`, `loadAssets()`, `timer` | Always start lowercase, capitalize inner words |
| Tables (state modules) | `camelCase` | `splash`, `menu`, `game`, `pause`, `credits` | State module variables use camelCase |
| Entities & systems (future) | `PascalCase` | `Player`, `Enemy`, `PhysicsSystem`, `AudioManager` | Capitalize first letter (future v0.3+) |
| Scope | `local` everywhere | `local timer = 0` | Global variables prohibited except: `Gamestate` (from hump), `love` (Love2D global), `Game` (future — single global reference for entities) |
| File names | `camelCase` | `splash.lua`, `nova2d.lua`, `main.lua` | One file per module |
| File structure | One module per file | `src/states/splash.lua` exports its state table | `return { ... }` at end of every module file |
| Separation | update / draw strict | `update(dt)` has NO draw logic; `draw()` has NO state mutation | Enforced by code review, not by linter (none available) |

### File Header Template

```lua
-- Nova2D — {description}
-- src/path/to/file.lua

local M = {}

-- ... module code ...

return M
```

---

## 7. Requirements

### R1: Directory Structure

The project SHALL contain the complete directory tree per the master plan.

- GIVEN the project root
- WHEN listing all directories
- THEN the following SHALL exist: `src/states/`, `src/entities/`, `src/systems/`, `src/utils/`, `assets/images/`, `assets/sounds/`, `assets/fonts/`, `libs/hump/`

### R2: Entry Points

The project SHALL have functional `main.lua` and `conf.lua`.

- GIVEN `love .` is run from the project root
- WHEN the game starts
- THEN the window SHALL be 800×600, resizable, vsync enabled, title "Nova2D"
- AND `main.lua` SHALL wire all 5 states via hump.gamestate and start on Splash

### R3: Splash State

The Splash state SHALL display the Nova2D logo and auto-transition after 3 seconds.

- GIVEN the game starts
- WHEN Splash state enters
- THEN the logo SHALL be displayed centered (or text fallback)
- AND after 3.0 seconds the state SHALL auto-transition to Menu
- AND no user input SHALL skip or interrupt the 3s timer

### R4: Menu State

The Menu state SHALL present 3 options navigable by keyboard and mouse.

- GIVEN Menu is active
- WHEN the user presses Up/Down
- THEN the selected item SHALL cycle through ["New Game", "Credits", "Quit"]
- WHEN the user presses Enter on an item
- THEN the corresponding action SHALL execute (switch state or quit)
- WHEN the user clicks an item
- THEN the same action SHALL execute
- WHEN the user clicks outside items
- THEN no action SHALL occur

### R5: Game State

The Game state SHALL be a blank placeholder accepting the Escape key.

- GIVEN Game is active
- WHEN Escape is pressed
- THEN Pause SHALL be pushed on top of Game via `Gamestate.push()`

### R6: Pause State

The Pause state SHALL overlay on Game without stopping Game updates.

- GIVEN Pause is active (pushed on Game)
- WHEN `update(dt)` is called
- THEN Game's update logic SHALL continue to execute
- AND a semi-transparent overlay SHALL be drawn on screen
- AND "PAUSED" text SHALL be displayed centered
- WHEN Escape is pressed
- THEN Pause SHALL be popped via `Gamestate.pop()`

### R7: Credits State

The Credits state SHALL list framework credits and return to Menu on any exit trigger.

- GIVEN Credits is active
- WHEN Escape / Enter / Backspace is pressed
- THEN the state SHALL switch to Menu
- WHEN any mouse button is clicked
- THEN the state SHALL switch to Menu

### R8: hump.gamestate Integration

The framework SHALL use hump.gamestate for all state management.

- GIVEN `main.lua` loads
- THEN `Gamestate.registerEvents()` SHALL be called to wire Love2D callbacks
- AND `Gamestate.switch(splash)` SHALL be the first state transition
- AND `Gamestate.push()`/`Gamestate.pop()` SHALL be used for the pause overlay

### R9: Error Resilience — Asset Loading

The framework SHALL handle missing/corrupt assets without crashing.

- GIVEN `assets/images/logo.png` is missing or corrupt
- WHEN Splash state enters
- THEN the Splash SHALL display centered "Nova2D" text instead of the image
- AND the 3s timer and auto-transition SHALL proceed normally

### R10: Error Resilience — Module Loading

The framework SHALL crash with a clear error for missing code modules.

- GIVEN `libs/hump/gamestate.lua` is missing
- WHEN `main.lua` is loaded
- THEN Love2D SHALL display a Lua error: module not found
- GIVEN any state file under `src/states/` is missing
- WHEN `main.lua` requires it
- THEN Love2D SHALL display a Lua error: module not found

---

## 8. Requirements Summary

| # | Requirement | Priority | Type | Scenarios |
|---|-------------|----------|------|-----------|
| R1 | Directory structure exists | MUST | Structure | 1 |
| R2 | Entry points (main.lua, conf.lua) functional | MUST | Functionality | 1 |
| R3 | Splash: logo + 3s auto-transition, non-skippable | MUST | State | 2 |
| R4 | Menu: 3 options, KB+mouse navigation | MUST | State | 5 |
| R5 | Game: empty placeholder, Esc → Pause | MUST | State | 1 |
| R6 | Pause: overlay, game updates continue, Esc toggle | MUST | State | 2 |
| R7 | Credits: library list, return on Esc/click | MUST | State | 2 |
| R8 | hump.gamestate integration | MUST | Integration | 1 |
| R9 | Asset error resilience (logo fallback) | MUST | Error | 1 |
| R10 | Module error handling (hard crash) | MUST | Error | 2 |

**Total**: 10 requirements, 18 scenarios (12 happy path, 6 edge/error)
