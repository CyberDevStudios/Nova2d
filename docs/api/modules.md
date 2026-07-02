# Modules

Reference of all Nova2D modules and their public APIs.

## Game engine

| Module | File | Purpose |
|---|---|---|
| main | `main.lua` | Entry point. Frozen — do not modify. |
| conf | `conf.lua` | Love2D window configuration. |
| splash | `src/states/splash.lua` | Splash screen with animated logo, nebula, and particle stars. |
| menu | `src/states/menu.lua` | Main menu with keyboard + mouse navigation. |
| game | `src/states/game.lua` | **Placeholder** — replace with your game code. |
| pause | `src/states/pause.lua` | Semi-transparent overlay with Resume / Return to Menu. |
| credits | `src/states/credits.lua` | Credits listing dependencies and authors. |
| hotreload | `src/hotreload.lua` | Lurker bootstrapper with deferred patching from `splash.enter()`. |

> The game engine modules are documented in detail in their respective API pages:
> [State Machine](state-machine.md), [Entity API](entity-api.md), [Configuration](configuration.md).

---

## Gestor (dependency manager)

The gestor runs as a **headless Love2D tool** — it uses Love2D's runtime but opens no
window. Commands are run from the project root:

```bash
love gestor/ install
love gestor/ install bump.lua
love gestor/ update
love gestor/ remove anim8
love gestor/ list
```

Entry point: `gestor/main.lua` — dispatches `args` to `cli.dispatch()` and exits.

### Gestor modules API

---

### `cli` — `gestor/cli.lua`

Command dispatcher and handler implementations.

#### `cli.dispatch(args)`

| Parameter | Type | Description |
|---|---|---|
| `args` | table | Array of strings, e.g. `{"install", "bump.lua"}` |

**Returns**: `true` on success, `false + error_message` on failure.

Parses `args[1]` as the command and routes it to the corresponding handler. Valid
commands: `install`, `update`, `remove`, `list`.

```lua
local cli = require("cli")
cli.dispatch({"install"})           -- install all dependencies
cli.dispatch({"install", "bump"})   -- install only bump
cli.dispatch({"update"})            -- check versions on GitHub
cli.dispatch({"remove", "anim8"})   -- uninstall
cli.dispatch({"list"})              -- list installed
```

---

### `manifest` — `gestor/manifest.lua`

Reads and validates `nova2d.lua`.

#### `manifest.read(project_root)`

| Parameter | Type | Description |
|---|---|---|
| `project_root` | string | Absolute path to the project root |

**Returns**: `manifest_table` on success, `nil + error_message` if the file is missing or has
validation errors.

Validations performed:

- The file must exist and be parseable as Lua
- Must return a table
- Each dependency must have `repo`, `version`
- If `type = "single"`, requires `file`
- `type` only accepts `"single"` or `"multi"`

```lua
local m = manifest.read("/path/to/project")
-- m.name      → "my-game"
-- m.version   → "1.0.0"
-- m.author    → "Your Name"
-- m.dependencies["bump.lua"]
--   → { repo = "kikito/bump.lua", version = "3.1.7", type = "single", file = "bump.lua" }
```

---

### `download` — `gestor/download.lua`

Handles downloads via `curl` and ZIP extraction with Windows/Unix support.

#### `download.single_file(name, dep, libs_path)`

| Parameter | Type | Description |
|---|---|---|
| `name` | string | Short library name (e.g. `"bump.lua"`) |
| `dep` | table | Dependency entry with `repo`, `version`, `file` |
| `libs_path` | string | Path to the `libs/` directory |

Downloads a single file from `raw.githubusercontent.com`. Creates a subdirectory
with the library name inside `libs_path` and places the file there.

```lua
local dep = { repo = "kikito/bump.lua", version = "3.1.7", type = "single", file = "bump.lua" }
download.single_file("bump.lua", dep, "/project/libs")
-- → /project/libs/bump.lua/bump.lua
```

**Returns**: `true` on success, `false + error_message` if curl fails or the file is empty.

#### `download.multi_file(name, dep, libs_path)`

| Parameter | Type | Description |
|---|---|---|
| `name` | string | Short library name (e.g. `"anim8"`) |
| `dep` | table | Dependency entry with `repo`, `version` |
| `libs_path` | string | Path to the `libs/` directory |

Downloads a ZIP from `api.github.com/repos/{repo}/zipball/{version}`, extracts it with
`unzip`, and moves the contents to `{libs_path}/{name}/`.

```lua
local dep = { repo = "kikito/anim8", version = "2.3.0", type = "multi" }
download.multi_file("anim8", dep, "/project/libs")
-- → /project/libs/anim8/*.lua
```

**Returns**: `true` on success, `false + error_message` if curl fails, there's no unzip, or the
file is corrupted.

#### `download.run_curl(cmd, dep_name)`

| Parameter | Type | Description |
|---|---|---|
| `cmd` | string | Full curl command with flags and URLs |
| `dep_name` | string | Name to display in the log |

**Returns**: `true` if curl exits with 0, `false + message` translated from the error code.

Handles common curl error codes:

| Code | Meaning |
|---|---|
| 6 | Could not resolve host |
| 7 | Connection refused |
| 18 | Incomplete download |
| 22 | Not found (404) |
| 28 | Timeout |
| 60 | SSL certificate error |

---

### `lock` — `gestor/lock.lua`

Manages the `nova2d-lock.lua` file with atomic read/write operations.

#### `lock.read(project_root)`

| Parameter | Type | Description |
|---|---|---|
| `project_root` | string | Absolute path to the project root |

Reads `nova2d-lock.lua`. If it doesn't exist, returns an empty table `{}`.

**Returns**: `lock_table` on success, `nil + error_message` if the file exists but cannot
be parsed.

```lua
local lf = lock.read("/project")
-- lf["bump.lua"] → { version = "3.1.7", installed = 1750617600 }
```

#### `lock.write(project_root, data)`

| Parameter | Type | Description |
|---|---|---|
| `project_root` | string | Absolute path to the project root |
| `data` | table | Table in the format `{ ["name"] = { version = "...", installed = timestamp } }` |

Writes the lockfile using atomic write (temporary file + `os.rename`). This
prevents corruption if the process is interrupted mid-write.

```lua
lock.write("/project", {
    ["bump.lua"] = { version = "3.1.7", installed = os.time() },
})
```

**Returns**: `true` on success, `false + error_message` if it cannot write.

#### `lock.compare(manifest, lockfile)`

| Parameter | Type | Description |
|---|---|---|
| `manifest` | table | Manifest table (`nova2d.lua`) |
| `lockfile` | table | Lockfile table (`nova2d-lock.lua`) |

Compares manifest dependencies against the lockfile. Returns only those that
are missing or have a different version.

**Returns**: `table` — array of `{ name = "...", dep = { ... } }` to install.

```lua
local todo = lock.compare(m, lf)
for _, item in ipairs(todo) do
    print("Need to install: " .. item.name)
end
```

#### `lock.remove_entry(project_root, name, lockfile)`

| Parameter | Type | Description |
|---|---|---|
| `project_root` | string | Absolute path to the project root |
| `name` | string | Name of the dependency to remove |
| `lockfile` | table | Lockfile table to modify |

Removes an entry from the lockfile and writes the changes.

```lua
lock.remove_entry("/project", "anim8", lf)
```

**Returns**: `true` on success, `false + error_message`.

---

### `util` — `gestor/util.lua`

System utilities: OS detection, path resolution, tool verification.

#### `util.get_os()`

**Returns**: `string` — `"Windows"`, `"OS X"`, `"Linux"` (values from `love.system.getOS()`).

#### `util.is_windows()`

**Returns**: `boolean` — `true` on Windows.

#### `util.find_tool(name)`

| Parameter | Type | Description |
|---|---|---|
| `name` | string | Executable name (e.g. `"curl"`, `"unzip"`) |

Searches for the tool in the system PATH. On Windows, tries `where` first without extension,
then with `.exe`.

**Returns**: `boolean`.

```lua
if util.find_tool("curl") then
    print("curl is available")
end
```

#### `util.tool_instructions(tool)`

| Parameter | Type | Description |
|---|---|---|
| `tool` | string | `"curl"` or `"unzip"` |

**Returns**: `string` with installation instructions specific to the detected OS.

```lua
print(util.tool_instructions("curl"))
-- "Install it: sudo apt install curl (Debian/Ubuntu), ..."
```

#### `util.get_project_root()`

**Returns**: `string` — absolute path to the project directory (the directory containing
the `main.lua` being executed).

Uses `love.filesystem.getSource()` to detect whether the project runs as a directory
or as a `.love` file.

#### `util.ensure_dir(path)`

| Parameter | Type | Description |
|---|---|---|
| `path` | string | Path of the directory to create |

Creates the directory and its parents if they don't exist. Uses `mkdir -p` on Unix, `if not exist
... mkdir` on Windows.

#### `util.format_timestamp(ts)`

| Parameter | Type | Description |
|---|---|---|
| `ts` | number | UNIX timestamp (seconds since epoch) |

**Returns**: `string` — date formatted as `"YYYY-MM-DD"`.

#### `util.normalize_exit_code(code)`

| Parameter | Type | Description |
|---|---|---|
| `code` | number | Exit code from `os.execute()` |

Normalizes exit codes from `os.execute()`, which vary between platforms.
On Unix the code is in the upper bits; on Windows it's direct.

**Returns**: `number` — normalized exit code (0 = success).

---

## Gestor internal flow

When you run `love gestor/ install`, the flow is:

```
love gestor/ install
  → main.lua receives args = {"install"}
  → cli.dispatch({"install"})
  → cmd_install()
       → util.find_tool("curl")
       → manifest.read(project_root)     → reads nova2d.lua
       → lock.read(project_root)         → reads nova2d-lock.lua
       → lock.compare(manifest, lock)     → what needs installing
       → for each pending:
            if type == "single"
                → download.single_file()  → curl to raw.githubusercontent.com
            if type == "multi"
                → download.multi_file()   → curl + unzip from GitHub API
       → lock.write(project_root, lock)   → updates lockfile
```
