# Tasks — v0.2 Dependency Manager ("Gestor")

**Change**: v0.2-dependency-manager
**Project**: Nova2D (Lua/Love2D framework)
**Total files**: 7 gestor modules + 2 updated stubs
**Estimated lines of code**: ~550 Lua
**Review forecast**: **Exceeds 400 lines** — chained PRs recommended

---

## Milestone 1: Skeleton

### Task 1.1 — Create gestor/ directory
- **Files**: (mkdir) `gestor/`
- **What**: Create the gestor directory at project root
- **Completion**: `gestor/` exists in project root
- **Depends on**: nothing
- **Effort**: small

### Task 1.2 — Create gestor/conf.lua
- **Files**: `gestor/conf.lua`
- **What**: Headless Love2D config. `t.modules.window = false`, `t.console = true`, disable audio/physics/joystick/touch/video
- **Completion**: gestor runs without opening a window
- **Depends on**: 1.1
- **Effort**: small

### Task 1.3 — Create gestor/main.lua
- **Files**: `gestor/main.lua`
- **What**: Entry point. Receives args from `love.load(args)`, dispatches via cli.lua, exits with code 0 (success) or 1 (error)
- **Completion**: `love gestor/` prints usage and exits cleanly
- **Depends on**: 1.1, 1.2
- **Effort**: small

---

## Milestone 2: Core Modules

### Task 2.1 — Create gestor/util.lua
- **Files**: `gestor/util.lua`
- **What**: Utility functions:
  - `get_os()` — wraps `love.system.getOS()`
  - `find_tool(name)` — search PATH for curl/unzip (cross-platform)
  - `tool_instructions(tool)` — OS-specific install instructions
  - `get_project_root()` — derive from `love.filesystem.getSource()` going one dir up
  - `ensure_dir(path)` — create directory if missing
  - `format_timestamp(ts)` — UNIX timestamp to human date
- **Completion**: All functions return correct values
- **Depends on**: 1.3
- **Effort**: small

### Task 2.2 — Create gestor/manifest.lua
- **Files**: `gestor/manifest.lua`
- **What**: Read and validate nova2d.lua:
  - `read(project_root)` — `io.open` + `pcall(dofile)`
  - Validate each dep has repo, version, type
  - type="single" requires file field
  - Return validated manifest table or error
- **Completion**: Parses valid nova2d.lua, errors on invalid
- **Depends on**: 2.1
- **Effort**: medium

### Task 2.3 — Create gestor/lock.lua
- **Files**: `gestor/lock.lua`
- **What**: Lockfile management:
  - `read(project_root)` — read nova2d-lock.lua or return empty table
  - `write(project_root, data)` — atomic write via .tmp + os.rename()
  - `compare(manifest, lockfile)` — returns list of deps to install/update
  - `remove_entry(project_root, name, lockfile)` — delete entry + rewrite
- **Completion**: Lockfile read/write verified atomic
- **Depends on**: 2.1
- **Effort**: medium

### Task 2.4 — Create gestor/download.lua
- **Files**: `gestor/download.lua`
- **What**: Download logic:
  - `single_file(name, dep, libs_path)` — curl single raw file
  - `multi_file(name, dep, libs_path)` — curl zip + unzip + move
  - `run_curl(cmd, dep_name)` — execute curl, check exit code
  - `curl_error_message(code)` — map exit codes to user messages
  - Retry partial downloads once
  - Verify file not empty after download
- **Completion**: Downloads work for both single and multi-file libs
- **Depends on**: 2.1
- **Effort**: large

### Task 2.5 — Create gestor/cli.lua
- **Files**: `gestor/cli.lua`
- **What**: Command dispatch:
  - `dispatch(args)` — parse args, route to handler
  - `cmd_install(args)` — full install or single dep install
  - `cmd_update(args)` — check GitHub for latest, update nova2d.lua, re-install
  - `cmd_remove(args)` — delete from libs/ + lockfile
  - `cmd_list(args)` — print installed deps table
- **Completion**: All 5 commands work via `love gestor/ <cmd>`
- **Depends on**: 2.2, 2.3, 2.4
- **Effort**: large

---

## Milestone 3: Integration

### Task 3.1 — Update nova2d.lua with real deps
- **Files**: `nova2d.lua`
- **What**: Replace stub with real dependency entries for hump, bump.lua, anim8, lurker, lovebird. Include name, version (matching what's available), type, and file for single-file libs.
- **Completion**: nova2d.lua has 5 real dependencies
- **Depends on**: nothing (can run in parallel with M1)
- **Effort**: small

### Task 3.2 — Update .gitignore
- **Files**: `.gitignore`
- **What**: Add entries for `libs/*` (user-installed deps) and `*.tmp` (atomic write temp files)
- **Completion**: gitignore updated
- **Depends on**: nothing
- **Effort**: small

### Task 3.3 — Integration test
- **Files**: verify all
- **What**: 
  - Run `love gestor/` — prints usage
  - Run `love gestor/ install` — downloads all 5 deps
  - Run `love gestor/ install bump.lua` — single dep install
  - Run `love gestor/ list` — shows installed
  - Run `love gestor/ update` — checks for updates
  - Run `love gestor/ remove anim8` — removes dep
- **Completion**: All 5 commands verified working
- **Depends on**: 2.5, 3.1
- **Effort**: medium

---

## Implementation Order

```
Task 1.1 → Task 1.2 → Task 1.3
                          ├── Task 2.1
                          │     ├── Task 2.2
                          │     ├── Task 2.3
                          │     └── Task 2.4
                          │           └── Task 2.5
                          │                 └── Task 3.3
                          ├── Task 3.1 (parallel)
                          └── Task 3.2 (parallel)
```

---

## Milestone Checkpoints

| # | Checkpoint | Command |
|---|---|---|
| M1 | gestor runs headless | `love gestor/` → "Usage: ..." |
| M2 | Modules complete | `love gestor/ list` → "No dependencies installed" |
| M3 | Full working gestor | `love gestor/ install` → downloads all deps |

---

## Review Workload Forecast

| Metric | Value |
|---|---|
| gestor modules | 7 files |
| Stubs updated | 2 files |
| Estimated Lua LOC | ~550 |
| **400-line budget** | **Exceeded** |
| **Chained PRs recommended** | **Yes** |

### Slice Proposal

Given the 550-line estimate, split into 2 PRs:

**PR-1 (Core, ~250 lines)**: Tasks 1.1 → 1.3 + 2.1 → 2.3 + 3.1 → 3.2
- gestor skeleton + util + manifest + lock + nova2d.lua update
- `love gestor/ list` works

**PR-2 (Download + CLI + Integration, ~300 lines)**: Tasks 2.4 → 2.5 → 3.3
- download.lua + cli.lua + integration test
- `love gestor/ install`, `update`, `remove` work
