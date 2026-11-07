# Testing

Nova2D ships with a [busted](https://lunarmodules.github.io/busted/) suite under `tests/`.
The systems are plain Lua, so they run without opening a window.

## Setup

```bash
luarocks install busted    # Lua 5.1+
```

From the project root:

```bash
busted
```

Expected output:

```
92 successes / 0 failures / 0 errors / 0 pending
```

Run one file or one test:

```bash
busted tests/spec/jump_spec.lua
busted --filter "coyote"
```

## Layout

```
tests/
├── love_stub.lua          -- minimal Love2D stubs for headless runs
└── spec/
    ├── timer_spec.lua
    ├── health_spec.lua
    ├── jump_spec.lua
    ├── input_spec.lua
    ├── camera_spec.lua
    ├── animation_spec.lua
    ├── audio_spec.lua
    ├── collision_spec.lua
    ├── entitymanager_spec.lua
    └── docs_examples_spec.lua
```

`.busted` adds `src/`, `libs/` and the repo root to the Lua path, so specs require
modules the same way the game does:

```lua
local Jump = require("src.systems.jump")
local EntityManager = require("src.systems.entitymanager")
```

## Love2D stubs

`tests/love_stub.lua` provides the small surface the systems touch: `love.timer.getTime`,
`love.keyboard.isDown`, `love.graphics` basics and `love.graphics.newQuad`. It is
deliberately minimal:

```lua
local stub = require("tests.love_stub")
stub.install()                 -- defines the global `love`

local input = require("src.systems.input")

stub.pressKey("left")
assert.is_true(input.new():isPressed("left"))
```

Helpers: `reset()`, `advance(dt)`, `pressKey(key)`, `releaseKey(key)`.

`love.joystick` is intentionally absent — the Input System guards for it, and that guard
is covered by a spec.

## What to test

- **Pure logic** (Jump, Health, Timer, EntityManager): no Love2D at all beyond the stub.
- **Regression cases**: constructor config vs. internal fields (the v0.6.1 bug class),
  and `false` config values (e.g. `variableHeight = false`).
- **Documented examples**: `docs_examples_spec.lua` executes the snippets published in
  the docs, so a broken page fails the build.
- **Integration**: the platformer demo can be exercised in a real Love2D process with
  `xvfb-run` (see CI), but unit-level wiring is covered by the EntityManager specs.

## Lint

```bash
luarocks install luacheck
luacheck src main.lua tests
```

`.luacheckrc` uses the `lua51+love` standard, ignores vendored `libs/` and allows the
busted globals in `tests/`. `main.lua` is the frozen entry point, so its intentionally
unused state requires are allowed there.

## CI

`.github/workflows/ci.yml` runs on pushes and pull requests:

1. **Lint & tests** — Lua 5.1, `luacheck` and `busted`.
2. **Love2D boot smoke test** — starts the game under Xvfb for a few seconds; a boot
   error fails the job.
3. **Installer checksum** — `sha256sum -c install.sh.sha256`.

Run the same checks locally before pushing:

```bash
luacheck src main.lua tests && busted
```
