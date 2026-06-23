# Modules

Reference of all Nova2D modules and their public APIs.

## Game engine

| Module | File | Purpose |
|---|---|---|
| main | `main.lua` | Entry point. Frozen — do not modify. |
| conf | `conf.lua` | Love2D window configuration. |
| splash | `src/states/splash.lua` | Logo display with auto-transition. |
| menu | `src/states/menu.lua` | Main menu with keyboard + mouse. |
| game | `src/states/game.lua` | Game screen placeholder. |
| pause | `src/states/pause.lua` | Pause overlay with Escape toggle. |
| credits | `src/states/credits.lua` | Credits screen. |
| hotreload | `src/hotreload.lua` | Lurker bootstrapper with deferred patching. |

## Gestor (dependency manager)

| Module | File | Purpose |
|---|---|---|
| cli | `gestor/cli.lua` | Command dispatcher. |
| manifest | `gestor/manifest.lua` | Reads and validates nova2d.lua. |
| download | `gestor/download.lua` | Downloads via curl, extracts zips. |
| lock | `gestor/lock.lua` | Manages nova2d-lock.lua. |
| util | `gestor/util.lua` | OS detection, paths, tool checks. |
