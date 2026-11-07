# Contributing to Nova2D

Thanks for your interest in improving Nova2D! This guide covers the basics.

## Getting started

```bash
git clone https://github.com/CyberDevStudios/Nova2d.git
cd Nova2d
love gestor/ install   # fetch dependencies into libs/
love .                 # boot the framework demo
```

Requirements: Love2D 11.x, and for the test suite Lua 5.1+ with
[busted](https://lunarmodules.github.io/busted/) and
[luacheck](https://github.com/lunarmodules/luacheck) (both installable via luarocks).

## Before you open a PR

```bash
luacheck src main.lua tests   # 0 warnings
busted                        # all specs green
love .                        # boots without errors
```

CI runs the same three checks (plus the installer checksum), so local runs save everyone
a round trip.

## Conventions

- **`main.lua` is frozen** — never modify the entry point
- One file per module, each file returns a table; internal requires use the `src.` prefix
- `camelCase` for variables/functions, `PascalCase` for entities and systems
- `local` everywhere; strict `update(dt)` (logic) / `draw()` (render) separation
- Entities use the metatable constructor pattern (`Player.new(x, y)`)
- Systems keep the shared API: `new(config)`, `update(dt)`, `reset()`, `on(event, cb)`
- Compatibility target: Love2D 11.x / Lua 5.1
- New behavior needs a spec; bug fixes need a regression spec

## Commits

Conventional Commits, short and in English:

```
feat(systems): add X
fix(camera): respect bounds config
docs: update entity guide
test: cover deferred removal
chore(lint): ...
```

One logical change per commit. Docs live under `docs/` (English) and are served on
[nova2d.dev](https://nova2d.dev/) from this repository.

## Reporting issues

Use the issue templates. For bugs, include the Love2D version (`love --version`), a
minimal reproduction, and the console output. For feature proposals, describe the use
case first — the API second.
