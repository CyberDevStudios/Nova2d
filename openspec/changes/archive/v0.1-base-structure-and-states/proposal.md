# Proposal: v0.1 — Base Structure + States

## Intent

Establish Nova2D's skeleton: directory tree, entry points (`main.lua`, `conf.lua`), and 5 fully functional game states (Splash → Menu → Game → Pause → Credits) using `hump.gamestate`. v0.1 is the foundation every future version builds on — it makes the framework runnable with `love .` from day one.

## Scope

### In Scope
- Full dir tree per `nova2d-plan.md`: `main.lua`, `conf.lua`, `nova2d.lua`, `nova2d-lock.lua`, `src/states/`, `src/entities/`, `src/systems/`, `src/utils/`, `assets/images/`, `assets/sounds/`, `assets/fonts/`, `libs/hump/`
- 5 state modules: Splash, Menu, Game, Pause, Credits
- `hump.gamestate` manually included in `libs/hump/`
- Placeholder `assets/images/logo.png` (generated)
- Stub files: `nova2d.lua`, `nova2d-lock.lua`

### Out of Scope
- Dependency manager (v0.2)
- Hot reload / lurker (v0.3)
- bump.lua, anim8, lovebird (v0.2+)
- Entity system, physics, collisions
- Custom fonts, audio, game logic
- Mouse hover effects
- Code in `src/entities/`, `src/systems/`, `src/utils/` (empty dirs only)

## Capabilities

### New Capabilities
- `splash-state`: Logo display, 3s auto-transition, mandatory first view
- `menu-state`: New Game / Credits / Quit, keyboard + mouse navigation
- `game-state`: Empty placeholder, receives focus from Menu
- `pause-state`: Escape toggle overlay, non-blocking (updates keep running)
- `credits-state`: Library listing, Escape/Enter/Backspace/click returns to Menu

### Modified Capabilities
None — no existing specs.

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Splash is mandatory first time | Establishes framework identity; 3s is short enough to not frustrate |
| Pause doesn't stop updates | Game state continues (e.g., animations, timers); visual overlay only |
| Menu uses KB + mouse | Keyboard for speed, mouse for accessibility (no hover complexity) |
| Window 800×600 resizable | Love2D default-friendly; resizable for dev flexibility |
| hump manually included | Gestor is v0.2; manual copy is the simplest path now |

## State Transitions

```
[Splash] ──(3s auto)──→ [Menu] ──(New Game)──→ [Game] ──(Esc)──→ [Pause]
                            │                      ↑                    │
                       (Credits)                    └──(Esc)────────────┘
                            │
                            ↓
                       [Credits] ──(Esc/Enter/click)──→ [Menu]
```

## File Inventory

| Path | Type | Description |
|------|------|-------------|
| `main.lua` | Entry | Gamestate wiring, state registry |
| `conf.lua` | Config | Window: 800×600, resizable, vsync, title "Nova2D" |
| `nova2d.lua` | Stub | Dependency manifest placeholder (v0.2) |
| `nova2d-lock.lua` | Stub | Lockfile placeholder (v0.2) |
| `src/states/splash.lua` | State | Logo, 3s timer, auto-transition |
| `src/states/menu.lua` | State | 3 options, KB+mouse input |
| `src/states/game.lua` | State | Empty placeholder |
| `src/states/pause.lua` | State | Esc toggle overlay |
| `src/states/credits.lua` | State | Library listing, return nav |
| `src/entities/` | Dir | Empty (future use) |
| `src/systems/` | Dir | Empty (future use) |
| `src/utils/` | Dir | Empty (future use) |
| `assets/images/logo.png` | Asset | Placeholder generated image |
| `assets/sounds/` | Dir | Empty (future use) |
| `assets/fonts/` | Dir | Empty (future use) |
| `libs/hump/` | Lib | Full hump library (gamestate + utils) |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| hump API incompatibility with Love2D 11.x | Low | Pin hump to latest known working commit |
| Logo placeholder too small or wrong format | Low | Provide fallback: text-based logo if image loading fails |
| State transitions race on fast input | Low | Use hump.gamestate's built-in transition queue |

## Rollback Plan

Trivial — no existing code to break. Rollback = delete all created files and dirs. Once v0.2 is built, rollback means `git revert` on the v0.1 commit.

## Dependencies

- **Love2D 11.x** (runtime requirement, documented in README)
- **hump** (vrld/hump) — manually included in `libs/hump/`

## Success Criteria

- [ ] `love .` from project root shows Splash → auto-transitions to Menu after 3s
- [ ] Menu responds to Up/Down/Enter AND mouse clicks
- [ ] New Game → Game state (empty screen); Escape → Pause overlay; Escape again → resume
- [ ] Credits shows library list; Escape/Enter/click returns to Menu
- [ ] All 5 state transitions work without errors
- [ ] Window is 800×600, resizable, vsync enabled, title "Nova2D"

## Impact Analysis

**Enables**: v0.2 (dependency manager), v0.3 (hot reload), any game built on Nova2D.

**Depends on**: Love2D 11.x, hump.gamestate.

**Breaks nothing** — clean slate project.

## Open Questions

None — scope and decisions are fully specified.

## Estimated Complexity

**Low**. 5 state modules + entry points + config + dir structure. No networking, no async, no file I/O beyond Love2D's `love.graphics`. Single developer, estimated 1–2 sessions.
