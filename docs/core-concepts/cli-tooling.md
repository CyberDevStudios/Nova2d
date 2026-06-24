# CLI & Tooling

Nova2D includes a dependency manager (gestor) that runs as a headless Love2D tool.

## Gestor commands

```bash
# Install all dependencies from nova2d.lua
love gestor/ install

# Install a specific library
love gestor/ install bump.lua

# Update all libraries to latest versions
love gestor/ update

# Remove a library
love gestor/ remove anim8

# List installed libraries
love gestor/ list
```

## How it works

The gestor reads your `nova2d.lua` file, downloads libraries from GitHub using `curl`, and installs them to `libs/`. It maintains a lockfile (`nova2d-lock.lua`) with exact versions for reproducible builds.

### Single-file libraries
Downloaded as raw files from `raw.githubusercontent.com`.

### Multi-file libraries
Downloaded as ZIP archives and extracted with `unzip`.

### Windows compatibility
On Windows, the gestor now uses OS-aware shell quoting and path handling to keep `curl` downloads and ZIP extraction stable across Git Bash, WSL, and Command Prompt environments.

## Tool requirements

| Tool | Required for | Notes |
|---|---|---|
| curl | All operations | Built into Windows 10+, macOS, and most Linux |
| unzip | Multi-file libs | Built into macOS and most Linux. Optional for Windows |

## Error handling

If a required tool is missing, the gestor shows OS-specific install instructions:

```
[ERROR] curl not found. Install it: sudo apt install curl (Debian/Ubuntu)
```

## Configuration file

Dependencies are declared in `nova2d.lua`:

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
