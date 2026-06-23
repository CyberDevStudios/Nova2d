# Design — v0.2 Dependency Manager ("Gestor")

**Change**: v0.2-dependency-manager
**Project**: Nova2D (Lua/Love2D framework)

---

## 1. Architecture Overview

### Directory Layout
```
project-root/
├── gestor/
│   ├── conf.lua          -- Headless Love2D config
│   ├── main.lua          -- Entry point, arg dispatch
│   ├── cli.lua           -- Command table + handler dispatch
│   ├── manifest.lua      -- Read + validate nova2d.lua
│   ├── download.lua      -- curl wrapper + ZIP extraction
│   ├── lock.lua          -- Read + write nova2d-lock.lua
│   └── util.lua          -- OS detection, path helpers
├── nova2d.lua            -- Manifest (user-edited)
├── nova2d-lock.lua       -- Lockfile (auto-generated)
├── libs/                 -- Installed dependencies
├── main.lua              -- FROZEN (no changes)
└── conf.lua              -- FROZEN (no changes)
```

### Module Dependency Graph
```
main.lua
  └── cli.lua
        ├── manifest.lua  (install, update)
        ├── download.lua  (install, update)
        │     └── util.lua
        ├── lock.lua      (install, update, remove, list)
        └── util.lua      (all commands)
```

### How Commands Flow

```
love gestor/ install
1. gestor/conf.lua: disable window
2. gestor/main.lua: love.load({"install"})
3. cli.dispatch("install")
4. Download list of deps from manifest
5. Compare with lockfile
6. For each missing/changed dep: download via curl
7. Write lockfile atomically
8. Print summary
```

---

## 2. File-by-File Design

### 2.1 gestor/conf.lua

```lua
function love.conf(t)
    t.window.title = "Nova2D Gestor"
    t.window.width = 0
    t.window.height = 0
    t.window.vsync = false
    t.modules.window = false       -- headless
    t.modules.audio = false
    t.modules.physics = false
    t.modules.joystick = false
    t.modules.touch = false
    t.modules.video = false
    t.console = true               -- show console on Windows
end
```

All game modules are disabled except those needed for file I/O and os.execute(). `t.console = true` ensures Windows users see CLI output even without a window.

### 2.2 gestor/main.lua

```lua
local cli = require("cli")

function love.load(args)
    -- args is a table, e.g. {"install", "bump.lua"}
    -- First arg after "love gestor/" is the command
    local ok, err = cli.dispatch(args)
    if not ok then
        print("[ERROR] " .. err)
        love.event.quit(1)
    else
        love.event.quit(0)
    end
end
```

Key points:
- `args` comes from command line: `love gestor/ install` → `args = {"install"}`
- Love2D passes arguments after the project path as the args table to love.load()
- Exit code 0 for success, 1 for error

### 2.3 gestor/cli.lua

```lua
local commands = {
    install = function(args) end,
    update  = function(args) end,
    remove  = function(args) end,
    list    = function(args) end,
}

function dispatch(args)
    if #args == 0 then
        return false, "Usage: love gestor/ [install|update|remove|list] [name]"
    end

    local cmd = args[1]
    local handler = commands[cmd]
    if not handler then
        return false, "Unknown command: " .. cmd .. ". Use: install, update, remove, list"
    end

    return handler(args)
end

return { dispatch = dispatch }
```

**install handler**:
- If `args[2]` exists → install only that dependency (by name key)
- If no args[2] → install all from manifest
- Read manifest → compare with lock → download loop → write lock

**update handler**:
- For each dep in manifest, check GitHub for latest version
- Update nova2d.lua with new versions
- Re-run install for changed deps

**remove handler**:
- Require args[2] (dep name)
- Delete libs/{name}/ directory
- Remove entry from lockfile
- Write updated lockfile

**list handler**:
- Read lockfile
- Print formatted table

### 2.4 gestor/manifest.lua

```lua
function read(project_root)
    local path = project_root .. "/nova2d.lua"
    local f, err = io.open(path, "r")
    if not f then
        return nil, "nova2d.lua not found at " .. path
    end

    local ok, manifest = pcall(dofile, path)
    if not ok then
        return nil, "Failed to parse nova2d.lua: " .. manifest
    end

    if type(manifest) ~= "table" then
        return nil, "nova2d.lua must return a table"
    end

    -- Validate each dependency
    for name, dep in pairs(manifest.dependencies or {}) do
        if not dep.repo then
            return nil, "Dependency '" .. name .. "' is missing required field 'repo'"
        end
        if not dep.version then
            return nil, "Dependency '" .. name .. "' is missing required field 'version'"
        end
        if dep.type == "single" and not dep.file then
            return nil, "Dependency '" .. name .. "' is type 'single' but missing 'file' field"
        end
        if dep.type ~= "single" and dep.type ~= "multi" then
            dep.type = "multi"  -- default to multi
        end
    end

    return manifest
end

return { read = read }
```

Validation order:
1. File exists
2. File is valid Lua (via pcall + dofile)
3. Returns a table
4. Each dep has required fields

### 2.5 gestor/download.lua

```lua
function single_file(name, dep, libs_path)
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s",
        dep.repo, dep.version, dep.file
    )
    local dest = libs_path .. "/" .. name .. "/"

    -- Create destination directory
    util.ensure_dir(dest)

    -- Construct curl command
    local cmd = string.format(
        "curl -fsSL --connect-timeout 10 --max-time 30 '%s' -o '%s%s'",
        url, dest, dep.file
    )

    local ok, exit_code = run_curl(cmd, name)
    if not ok then return false, exit_code end

    -- Verify file is not empty
    local f = io.open(dest .. dep.file, "r")
    if f then
        local size = f:seek("end")
        f:close()
        if size == 0 then
            os.remove(dest .. dep.file)
            return false, "Downloaded file is empty"
        end
    end

    return true
end

function multi_file(name, dep, libs_path)
    local url = string.format(
        "https://api.github.com/repos/%s/zipball/%s",
        dep.repo, dep.version
    )
    local tmp_zip = os.tmpname() .. ".zip"
    local tmp_dir = os.tmpname()

    -- Check unzip
    if not util.find_tool("unzip") then
        return false, "unzip not found. Required for multi-file libraries."
    end

    -- Download zip
    local cmd = string.format(
        "curl -fsSL --connect-timeout 10 --max-time 60 '%s' -o '%s'",
        url, tmp_zip
    )
    local ok, code = run_curl(cmd, name)
    if not ok then return false, code end

    -- Extract
    local extract_cmd = string.format("unzip -o '%s' -d '%s'", tmp_zip, tmp_dir)
    local extract_ok = os.execute(extract_cmd)
    if extract_ok ~= 0 then
        os.remove(tmp_zip)
        os.execute("rm -rf '" .. tmp_dir .. "'")
        return false, "Failed to extract archive"
    end

    -- Get extracted directory name
    local dir_handle = io.popen("ls -1 '" .. tmp_dir .. "'")
    local extracted_dir = dir_handle:read("*l")
    dir_handle:close()

    -- Move contents to libs/{name}/
    local dest = libs_path .. "/" .. name
    util.ensure_dir(dest)
    os.execute(string.format("mv '%s/%s/'* '%s/'", tmp_dir, extracted_dir, dest))

    -- Cleanup
    os.remove(tmp_zip)
    os.execute("rm -rf '" .. tmp_dir .. "'")

    return true
end

function run_curl(cmd, dep_name)
    print("> " .. dep_name .. " -> downloading...")
    local exit_code = os.execute(cmd)
    -- os.execute returns: actual exit code on Windows, exit_code*256 on Unix
    -- Normalize: if exit_code ~= 0, it failed
    if exit_code ~= 0 then
        local msg = curl_error_message(exit_code)
        return false, msg
    end
    return true
end

function curl_error_message(code)
    -- Map normalized exit codes to user messages
    local messages = {
        [6]  = "Could not resolve host. Check internet connection.",
        [7]  = "Connection refused by server.",
        [22] = "Not found. Check repo or version in nova2d.lua.",
        [28] = "Connection timed out after 30s.",
        [18] = "Download incomplete. Retry.",
        [60] = "SSL certificate error. Update CA certs or use type=insecure.",
    }
    return messages[code] or "curl failed with exit code " .. code
end

return { single_file = single_file, multi_file = multi_file }
```

### 2.6 gestor/lock.lua

```lua
function read(project_root)
    local path = project_root .. "/nova2d-lock.lua"
    local f = io.open(path, "r")
    if not f then return {} end  -- no lockfile yet

    local ok, data = pcall(dofile, path)
    if not ok then
        return nil, "Failed to parse nova2d-lock.lua. Delete it and re-run install."
    end

    return data or {}
end

function write(project_root, data)
    local path = project_root .. "/nova2d-lock.lua"
    local tmp_path = path .. ".tmp"

    -- Generate Lua content
    local lines = {"-- Generated automatically. Do not edit.\nreturn {"}
    for name, entry in pairs(data) do
        table.insert(lines, string.format(
            '    ["%s"] = { version = "%s", installed = %d },',
            name, entry.version, entry.installed
        ))
    end
    table.insert(lines, "}")

    -- Atomic write
    local f, err = io.open(tmp_path, "w")
    if not f then
        return false, "Cannot write lockfile: " .. err
    end
    f:write(table.concat(lines, "\n"))
    f:close()

    local ok, rename_err = os.rename(tmp_path, path)
    if not ok then
        os.remove(tmp_path)
        return false, "Failed to finalize lockfile: " .. (rename_err or "unknown error")
    end

    return true
end

function compare(manifest, lockfile)
    -- Returns:
    -- to_install: list of {name, dep} that need installing (new or changed)
    -- This does NOT auto-remove anything
    local to_install = {}
    for name, dep in pairs(manifest.dependencies or {}) do
        local locked = lockfile[name]
        if not locked or locked.version ~= dep.version then
            table.insert(to_install, { name = name, dep = dep })
        end
    end
    return to_install
end

function remove_entry(project_root, name, lockfile)
    lockfile[name] = nil
    return write(project_root, lockfile)
end

return { read = read, write = write, compare = compare, remove_entry = remove_entry }
```

### 2.7 gestor/util.lua

```lua
local util = {}

function util.get_os()
    local os_name = love.system.getOS()
    -- Returns "Windows", "OS X", "Linux", or "Android"
    return os_name
end

function util.find_tool(name)
    -- On Windows, check both name and name.exe
    if util.get_os() == "Windows" then
        local r = os.execute("where " .. name .. " >nul 2>nul")
        if r == 0 then return true end
        r = os.execute("where " .. name .. ".exe >nul 2>nul")
        return r == 0
    else
        local r = os.execute("command -v " .. name .. " >/dev/null 2>&1")
        return r == 0
    end
end

function util.tool_instructions(tool)
    local os = util.get_os()
    if tool == "curl" then
        if os == "Linux" then
            return "Install it: sudo apt install curl (Debian/Ubuntu), sudo pacman -S curl (Arch), sudo dnf install curl (Fedora)"
        elseif os == "OS X" then
            return "Install it: brew install curl"
        elseif os == "Windows" then
            return "Win10+ includes curl.exe. If missing: https://curl.se/windows/"
        end
    elseif tool == "unzip" then
        if os == "Linux" then
            return "Install it: sudo apt install unzip (Debian/Ubuntu), sudo pacman -S unzip (Arch)"
        elseif os == "OS X" then
            return "Install it: brew install unzip"
        elseif os == "Windows" then
            return "Install it from: https://infozip.sourceforge.net/ or use: choco install unzip"
        end
    end
    return "Install " .. tool .. " for your OS."
end

function util.get_project_root()
    -- love.filesystem.getSource() returns the path to the running .love or directory
    -- When running "love gestor/", this returns /abs/path/to/gestor/
    -- The project root is one level up
    local source = love.filesystem.getSource()
    -- /abs/path/project/gestor/ -> /abs/path/project/
    return source:match("^(.+)/[^/]+$") or source
end

function util.ensure_dir(path)
    -- Lua 5.1 doesn't have lfs.mkdir. Use os.execute or love.filesystem
    -- love.filesystem.createDirectory works with the love.save directory,
    -- but for project dirs we use os.execute
    if util.get_os() == "Windows" then
        os.execute('if not exist "' .. path .. '" mkdir "' .. path .. '"')
    else
        os.execute("mkdir -p '" .. path .. "'")
    end
end

function util.format_timestamp(ts)
    return os.date("%Y-%m-%d", ts)
end

return util
```

---

## 3. Data Structures

### Command Dispatch Table
```lua
-- cli.lua internal
commands = {
    install = function(args) end,  -- args = {"install"} or {"install", "bump.lua"}
    update  = function(args) end,
    remove  = function(args) end,  -- args = {"remove", "anim8"}
    list    = function(args) end,
}
```

### Manifest Entry
```lua
-- From nova2d.lua
dep = {
    repo    = "kikito/bump.lua",    -- GitHub "user/repo"
    version = "3.1.7",              -- Tag, branch, or commit
    type    = "single",             -- "single" | "multi"
    file    = "bump.lua",           -- only for type="single"
}
```

### Lockfile Entry
```lua
-- In nova2d-lock.lua
entry = {
    version   = "3.1.7",
    installed = 1750617600,         -- os.time() UNIX timestamp
}
```

### Compare Result
```lua
-- From lock.compare()
to_install = {
    { name = "bump.lua", dep = { repo = "kikito/bump.lua", version = "3.1.7", type = "single", file = "bump.lua" } },
    { name = "anim8",    dep = { repo = "kikito/anim8",    version = "2.3.0", type = "multi" } },
}
```

---

## 4. Curl Exit Code Mapping

| Code | Meaning | User Message |
|---|---|---|
| 0 | Success | — |
| 6 | DNS resolution failed | "Could not resolve host. Check internet connection." |
| 7 | Connection refused | "Connection refused by server." |
| 18 | Partial transfer | "Download incomplete. Retry." |
| 22 | HTTP error (404, etc.) | "Not found. Check repo or version in nova2d.lua." |
| 28 | Timeout | "Connection timed out after 30s." |
| 52 | Server reply nothing | "Server returned empty response." |
| 56 | Network failure | "Network failure. Check connection." |
| 60 | SSL certificate | "SSL certificate error. Update CA certs." |

**Note on os.execute() exit code**: On Unix, `os.execute()` returns `exit_code * 256`. On Windows, it returns the actual exit code. The design should normalize this:

```lua
-- Normalize os.execute return value
local function normalize_exit(code)
    if code == 0 then return 0 end
    if code < 0 then return code end
    -- On Unix, code = exit_value * 256
    -- Try to extract the actual exit value
    if code % 256 == 0 then
        return code // 256
    end
    return code
end
```

---

## 5. Update Command Design

### Version Detection

The `update` command needs to find the latest version of each GitHub repo. Approach:

**Use GitHub API** for release detection:
```
GET https://api.github.com/repos/{user}/{repo}/releases/latest
→ Response: { "tag_name": "3.2.0" }
```

Fallback: if no releases, use the default branch name.

### Update Flow
1. For each dep in manifest, fetch latest release tag from GitHub API
2. Compare with current version in nova2d.lua
3. If different:
   - Update version in nova2d.lua
   - Print "bump.lua updated: 3.1.7 -> 3.2.0"
4. After scanning all deps, run install for changed ones
5. Write updated lockfile

### Caveat
- Unauthenticated GitHub API has a rate limit of 60 requests/hour
- With 5 libraries, one update = 5 requests. Well within limit.
- Add a 1-second delay between requests to be polite.

---

## 6. Error Handling Strategy

| Error | Detection | Response |
|---|---|---|
| Missing tool | `util.find_tool()` at start | Print instructions, exit 1 |
| No manifest | `io.open()` fails | Print path, exit 1 |
| Bad manifest | `pcall(dofile)` fails | Print parse error, exit 1 |
| Curl timeout | Exit code 28 | Print message, continue next dep or abort |
| Curl 404 | Exit code 22 | Print message, continue next dep |
| Partial download | Exit code 18 | Retry once, then abort that dep |
| Write permission | `io.open("w")` fails | Print path, exit 1 |
| Lockfile atom write | `os.rename()` fails | Print error, exit 1 |

### Atomic Write Guarantee

```
1. Write content to nova2d-lock.lua.tmp
2. fsync / close file
3. os.rename("nova2d-lock.lua.tmp", "nova2d-lock.lua")
4. If step 3 fails: delete .tmp file, print error
```

This guarantees the lockfile is never truncated or partially written.

---

## 7. OS-Specific Handling

### Path Separators
Lua's `io.open()` works with both `/` and `\` on Windows. Always use `/` — Lua normalizes it.

### Temporary Files
- Use `os.tmpname()` for temporary download/extract locations
- Ensure cleanup with `os.remove()` in all code paths (including errors)

### Console Output
- `t.console = true` in conf.lua ensures Windows users see output
- Use `print()` for all output — it goes to stdout

---

## 8. Constants and Configuration

```lua
-- download.lua constants
local CURL_FLAGS = "-fsSL --connect-timeout 10 --max-time 30"
local CURL_FLAGS_ZIP = "-fsSL --connect-timeout 10 --max-time 60"
local RETRY_LIMIT = 1

-- util.lua
local RAW_URL_TEMPLATE = "https://raw.githubusercontent.com/%s/%s/%s"
local ZIP_URL_TEMPLATE = "https://api.github.com/repos/%s/zipball/%s"
local GITHUB_API_RELEASES = "https://api.github.com/repos/%s/releases/latest"
```

---

## 9. Architecture Decisions

| AD | Decision | Rationale |
|---|---|---|
| AD-1 | Separate gestor/ directory | main.lua stays frozen, no window flash, clean tool/runtime split |
| AD-2 | os.execute() for curl | Lua 5.1 has no HTTP client, Love2D has no love.http in headless mode |
| AD-3 | io.open() instead of love.filesystem | Gestor reads project files (not sandboxed), love.filesystem works within love.save dir |
| AD-4 | Atomic writes for lockfile | Prevents corruption if gestor is interrupted mid-write |
| AD-5 | pcall + dofile for parsing | Love2D doesn't include a JSON parser, Lua tables are the native config format |
| AD-6 | No luarocks dependencies | Zero setup, works on any machine with Love2D |
| AD-7 | Version string, not commit hash | Simpler, human-readable, avoids GitHub API calls for lock reads |
