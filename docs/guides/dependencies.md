# Dependencies

Nova2D uses `nova2d.lua` to declare project dependencies and `nova2d-lock.lua` to lock exact versions.

## Declaring dependencies

Edit `nova2d.lua` in your project root:

```lua
return {
    name    = "my-game",
    version = "1.0.0",
    author  = "Your Name",

    dependencies = {
        ["bump.lua"] = {
            repo = "kikito/bump.lua",
            version = "3.1.7",
            type = "single",
            file = "bump.lua"
        },
        ["anim8"] = {
            repo = "kikito/anim8",
            version = "2.3.0",
            type = "multi"
        },
    },
}
```

### Fields

| Field | Required | Description |
|---|---|---|
| `repo` | yes | GitHub user/repository |
| `version` | yes | Tag, branch, or commit |
| `type` | yes | "single" or "multi" file library |
| `file` | if single | Filename for single-file libs |

## Installing

```bash
love gestor/ install
```

This reads `nova2d.lua`, compares with `nova2d-lock.lua`, and downloads any missing or updated dependencies.

## The lockfile

`nova2d-lock.lua` is auto-generated and should not be edited manually:

```lua
-- Generated automatically. Do not edit.
return {
    ["bump.lua"] = { version = "3.1.7", installed = 1750617600 },
    ["anim8"]    = { version = "2.3.0", installed = 1750617600 },
}
```

It tracks the exact version and installation timestamp for reproducible builds.

## Updating

```bash
love gestor/ update
```

Checks GitHub for the latest release of each dependency, updates `nova2d.lua`, and reinstalls changed libraries.

## Dependency lifecycle

| Action | Command |
|---|---|
| Install all | `love gestor/ install` |
| Install one | `love gestor/ install bump.lua` |
| Update all | `love gestor/ update` |
| Remove one | `love gestor/ remove anim8` |
| List installed | `love gestor/ list` |
