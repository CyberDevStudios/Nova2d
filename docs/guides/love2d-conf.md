# love.conf in Love2D — Configure Your Game

Love2D's `conf.lua` is a single `love.conf(t)` function that sets your game's identity, window, audio, modules and more before the engine boots. Nova2D ships this file with sensible defaults, so you only edit the fields you care about — and adds `nova2d.lua` for project metadata and dependencies.

## The vanilla Love2D way

Create `conf.lua` in your project root. `love.conf(t)` receives a table of all settings; the default values are already set, so you override only what you need:

```lua
function love.conf(t)
    t.identity = "mygame"              -- save directory name
    t.window.title = "My Game"
    t.window.width = 1024
    t.window.height = 768
    t.window.resizable = true
    t.window.vsync = 1
    t.modules.audio = true             -- load the audio module
    t.modules.joystick = false         -- skip unused modules
end
```

> **Note:** `t.modules.*` controls which Love2D modules load at startup. Disabling unused ones (physics, joystick, audio) reduces startup time and memory usage.

## The Nova2D way

The Nova2D template's `conf.lua` already sets everything with sensible defaults — identity `"nova2d"`, 800x600 resizable window, vsync on, and audio/physics/joystick disabled. You just override what differs:

```lua
function love.conf(t)
    t.window.title = "My Game"
    t.window.width = 1024
    t.window.height = 768
    t.modules.audio = true
end
```

Project-level metadata lives in a second file, `nova2d.lua`, which the dependency manager reads:

```lua
return {
    name    = "my-game",
    version = "1.0.0",
    author  = "Your Name",

    dependencies = {
        ["anim8"] = {
            repo = "kikito/anim8",
            version = "2.3.0",
            type = "multi"
        },
    },
}
```

## Vanilla → Nova2D

| Concern | Vanilla Love2D | Nova2D |
|---|---|---|
| Window title / size | `t.window.title = ...` in `love.conf` | Same field — template ships with defaults, edit only what you need |
| Save directory | `t.identity = "mygame"` | `t.identity = "nova2d"` by default |
| Modules | `t.modules.audio = true` | `t.modules.audio = false` by default — enable only what you use |
| Resizable / vsync / icon | `t.window.*` flags | Same — plain `conf.lua` fields |
| Project metadata | Manual files | `nova2d.lua` manifest: name, version, author, dependencies |
| Reproducible installs | Manual library management | `nova2d-lock.lua` lockfile + `love gestor/ install` |

## Next step

`conf.lua` stays vanilla Love2D in Nova2D — nothing magical. What's different is the layer around it. See the [Configuration API](../api/configuration.md) for the full reference: every `conf.lua` field with defaults, plus the `nova2d.lua` manifest and lockfile.