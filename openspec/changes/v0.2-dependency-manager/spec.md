# Spec — v0.2 Dependency Manager ("Gestor")

**Change**: v0.2-dependency-manager
**Project**: Nova2D (Lua/Love2D framework)

---

## R1 — Headless Entry Point

**Requirement**: The gestor MUST have its own `gestor/conf.lua` with `t.modules.window = false` so it runs headless without opening a window.

**Scenarios**:
- `love gestor/` runs without displaying any window
- `love gestor/` exits cleanly after executing the command
- `love gestor/` without arguments shows usage instructions

---

## R2 — Command Dispatch

**Requirement**: The gestor MUST support exactly 5 commands dispatched from `gestor/main.lua`: `install`, `install <name>`, `update`, `remove <name>`, `list`.

**Scenarios**:
- `love gestor/ install` — runs full install for all dependencies
- `love gestor/ install bump.lua` — installs only bump.lua
- `love gestor/ update` — updates all dependencies to latest versions
- `love gestor/ remove anim8` — removes anim8 from libs/ and lockfile
- `love gestor/ list` — prints installed dependencies table
- `love gestor/ unknown` — prints "Unknown command: unknown. Usage: ..."
- `love gestor/ install` with no manifest file — prints error and exits

---

## R3 — Tool Detection (curl + unzip)

**Requirement**: The gestor MUST detect curl and unzip before any network operation. If missing, print OS-specific install instructions and exit with code 1.

**Scenarios**:
- curl found on Linux (`which curl` or `command -v curl`) → proceed
- curl found on Windows (`where curl.exe` or `where curl`) → proceed
- curl not found on Debian/Ubuntu → "curl not found. Install it: sudo apt install curl"
- curl not found on macOS → "curl not found. Install it: brew install curl"
- curl not found on Windows → "curl.exe not found. Win10+ should include it. If not: https://curl.se/windows/"
- unzip not found before multi-file download → "unzip not found. Install instructions..."
- unzip not needed for single-file downloads → skip check

---

## R4 — Manifest Parsing

**Requirement**: `manifest.lua` MUST read `nova2d.lua` from the project root and validate its structure. It MUST return a table of dependencies with repo, version, type, and (if single) file fields.

**Scenarios**:
- Valid nova2d.lua with 3 dependencies → parsed correctly
- Missing nova2d.lua → "nova2d.lua not found at {path}. Create one or run `love gestor/ init`."
- Malformed nova2d.lua (syntax error) → "Failed to parse nova2d.lua: {error}"
- Dependency missing `repo` field → "Dependency '{name}' is missing required field 'repo'"
- Dependency with type="single" missing `file` field → "Dependency '{name}' is type 'single' but missing 'file' field"
- Dependency with type="multi" has `file` field → allowed, `file` is ignored for multi

---

## R5 — Single-File Download

**Requirement**: `download.lua` MUST download single-file libraries from `https://raw.githubusercontent.com/{repo}/{version}/{file}` using curl, and place them at `libs/{name}`.

**URL construction**:
```
https://raw.githubusercontent.com/kikito/bump.lua/3.1.7/bump.lua
→ dest: libs/bump.lua/bump.lua
```

**Scenarios**:
- Successful download → file exists at `libs/{name}/{file}`, correct size
- curl returns 404 (exit code 22) → "Not found: {url}. Check repo or version in nova2d.lua"
- curl times out (exit code 28) → "Connection timed out. Check your internet connection."
- curl SSL error (exit code 60) → "SSL certificate error. Update CA certs or set type="insecure" in nova2d.lua"
- curl partial download (exit code 18) → "Download incomplete. Retrying..."
- Zero-byte file after download → "Downloaded file is empty. Check repo or version."
- Destination directory doesn't exist → create it before writing

---

## R6 — Multi-File (ZIP) Download

**Requirement**: `download.lua` MUST download multi-file libraries from `https://api.github.com/repos/{repo}/zipball/{version}` using curl, extract with unzip, and move contents to `libs/{name}/`.

**URL construction**:
```
https://api.github.com/repos/vrld/hump/zipball/main
→ download to /tmp/hump-{random}.zip
→ extract to /tmp/hump-extract/
→ move contents to libs/hump/
→ remove /tmp/hump-*.zip and /tmp/hump-extract/
```

**Scenarios**:
- Successful multi-file download → files exist at `libs/{name}/`
- ZIP download fails → same error handling as single-file
- unzip fails → "Failed to extract archive. unzip may be missing or the archive is corrupt."
- Downloaded file is not a valid ZIP → "Downloaded file is not a valid archive."
- GitHub returns rate limit page → "GitHub rate limit exceeded. Wait a few minutes and try again."
- Temp directory creation fails → "Cannot create temporary directory at {path}"

---

## R7 — Lockfile Management

**Requirement**: `lock.lua` MUST read and write `nova2d-lock.lua` atomically. It MUST store version + UNIX timestamp for each dependency. Writes MUST go to a `.tmp` file first then `os.rename()` to the real path.

**Scenarios**:
- Lockfile exists and is valid → parsed correctly
- Lockfile doesn't exist → return empty table
- Lockfile is malformed Lua → "Failed to parse nova2d-lock.lua. Delete it and re-run install."
- Atomic write succeeds → lockfile contains correct data
- Atomic write fails (disk full) → "Failed to write lockfile. Disk may be full."
- Concurrent write → not handled (single-user tool)

---

## R8 — Install Flow

**Requirement**: `love gestor/ install` MUST compare manifest against lockfile and install only missing or version-changed dependencies.

**Scenarios**:
- First install (no lockfile) → all 3 dependencies installed
- Re-run install with same versions → all skipped, "All dependencies are up to date."
- Re-run install after bumping a version in nova2d.lua → only that one reinstalled
- Install single dep (`love gestor/ install bump.lua`) → only bump.lua checked/installed
- Install with no internet → first download fails → "Failed to download bump.lua: {error}. Aborting."
- All deps already installed → "3 dependencies up to date. (0 installed, 0 updated)"

---

## R9 — Update Flow

**Requirement**: `love gestor/ update` MUST check GitHub for the latest version of each dependency, update `nova2d.lua` with the new versions, then re-install changed deps.

**Scenarios**:
- All deps at latest → "All dependencies are up to date."
- Some deps outdated → "bump.lua updated: 3.1.7 -> 3.2.0"
- GitHub unreachable → "Failed to check GitHub for updates. Check your connection."
- Update changes nova2d.lua → file rewritten with new version numbers
- Lockfile updated after re-install → new version + timestamp in lockfile

---

## R10 — Remove Flow

**Requirement**: `love gestor/ remove <name>` MUST delete the dependency directory from `libs/` and remove the entry from the lockfile. It MUST NOT modify `nova2d.lua`.

**Scenarios**:
- Dependency exists in libs/ and lockfile → deleted from both
- Dependency not installed → "Dependency '{name}' is not installed."
- `rm -rf` fails (permissions) → "Failed to remove {path}. Check permissions."
- After removal, lockfile no longer has the entry

---

## R11 — List Flow

**Requirement**: `love gestor/ list` MUST read the lockfile and print a table of installed dependencies with version and installation date.

**Output format**:
```
Installed dependencies:
  bump.lua   3.1.7   2026-06-22
  hump       main    2026-06-22
```

**Scenarios**:
- Lockfile has 2 entries → table printed with 2 rows
- Lockfile is empty → "No dependencies installed."
- Lockfile doesn't exist → "No dependencies installed."

---

## R12 — Error Message Format

**Requirement**: All error messages MUST include what went wrong AND what the user can do about it.

**Format**: `[ERROR] {what happened}. {action item}.`

**Examples**:
- `[ERROR] curl not found. Install it: sudo apt install curl`
- `[ERROR] Connection timed out for bump.lua. Check your internet and try again.`
- `[ERROR] Failed to parse nova2d.lua. Line 15: unexpected symbol near '}'`

---

## R13 — Success Message Format

**Requirement**: All success messages MUST use `> ` prefix and show clear status.

**Examples**:
- `> 3 dependencies installed in 1.2s`
- `> bump.lua 3.1.7 -> downloading...`
- `> bump.lua installed`
- `> All dependencies are up to date.`
- `> anim8 removed from libs/`

---

## Scenario Summary

| ID | Requirement | Scenarios |
|---|---|---|
| R1 | Headless entry point | 3 |
| R2 | Command dispatch | 7 |
| R3 | Tool detection | 7 |
| R4 | Manifest parsing | 6 |
| R5 | Single-file download | 8 |
| R6 | Multi-file download | 6 |
| R7 | Lockfile management | 6 |
| R8 | Install flow | 6 |
| R9 | Update flow | 5 |
| R10 | Remove flow | 4 |
| R11 | List flow | 3 |
| R12 | Error message format | guideline |
| R13 | Success message format | guideline |

**Total**: 13 requirements, ~65 scenarios
