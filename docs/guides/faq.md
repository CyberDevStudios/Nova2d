# FAQ & Troubleshooting

## Installation

### The curl installer doesn't work on Windows

PowerShell has a `curl` alias that points to `Invoke-WebRequest`, not the real `curl`.
That alias does not support the `-fsSL` flags.

**Solution**: use Git Bash, WSL, or manual installation:

```bash
git clone https://github.com/CyberDevStudios/Nova2d.git my-game
cd my-game
love .
```

### "bash: curl: command not found"

`curl` is not installed. On most systems you can install it with the package
manager:

```bash
# Debian / Ubuntu
sudo apt install curl

# macOS (comes pre-installed)
# Windows 10/11 (comes pre-installed)
```

### "bash: love: command not found"

Love2D is not installed or not in your `PATH`.

1. Download Love2D 11.x from [love2d.org](https://love2d.org/)
2. On Linux, extract the tarball and add it to PATH, or install via package manager:
   ```bash
   # Ubuntu / Debian
   sudo apt install love
   ```
3. On macOS, move `love.app` to `/Applications` and run from the terminal or create a
   symlink:
   ```bash
   ln -s /Applications/love.app/Contents/MacOS/love /usr/local/bin/love
   ```
4. On Windows, make sure the Love2D folder is in your system `PATH`, or
   use the full path.

### "unzip not found" when installing dependencies

Some libraries (like `anim8` or `hump`) come as ZIP files and require `unzip`.

```bash
# Debian / Ubuntu
sudo apt install unzip

# macOS (comes pre-installed)
# Windows (Git Bash ships unzip)
```

### The splash looks wrong or there are no particles

The splash uses images (`assets/images/logo.png`, `assets/images/icon32.png`). If the
images are missing or corrupted, the splash will show without the logo but will still work.

Verify that the files exist:

```bash
ls assets/images/
# Should show: icon32.png  logo.png  (and others)
```

---

## Love2D / Runtime

### Error: "module 'hump.gestalt' not found"

Nova2D requires dependencies to be installed. If you cloned the repo without running
the installer, the libraries won't be in `libs/`.

```bash
love gestor/ install
```

### Error: attempt to call a nil value on Gamestate

If you modified `main.lua`, you may have broken the initialization sequence. Nova2D
freezes `main.lua` for this reason. Check that you haven't touched it:

```lua
-- main.lua MUST look exactly like this:
function love.load()
    Gamestate.registerEvents()
    Gamestate.switch(splash)
end
```

### No sound is playing

Nova2D disables the audio module by default to improve startup time.

In `conf.lua`:

```lua
t.modules.audio = true   -- change from false to true
```

### The window doesn't resize

Check that `conf.lua` has:

```lua
t.window.resizable = true
```

If it's already `true` and it still doesn't work, the current state might not implement
`resize(w, h)`. It's not mandatory, but without that callback the UI can shift around.

---

## Hot Reload

### Changes don't apply on save

First verify that:

1. You are editing files inside `src/` (hot reload does not monitor `main.lua`,
   `conf.lua`, or `libs/`)
2. Hot reload bootstraps from `splash.enter()` — if you don't see the splash for some
   reason (e.g. if you start directly in another state), hot reload is not active
3. You are saving the file to disk (some remote editors don't trigger the
   filesystem watcher correctly)

If all of that is fine, touch the file again or restart `love .`.

### Error with hot reload after modifying an entity

If an entity doesn't reload properly, it could be because the module stores state at the
module level (not the instance level). Hot reload clears the module and reloads it, losing
that state.

**Bad** (state on the module, not the instance):
```lua
local Enemy = {}
local counter = 0  -- ← THIS is lost on hot reload

function Enemy:update(dt)
    counter = counter + 1
end
```

**Good** (state on the instance):
```lua
local Enemy = {}

function Enemy:enter()
    self.counter = 0  -- ← each instance has its own counter
end

function Enemy:update(dt)
    self.counter = self.counter + 1
end
```

### Hot reload doesn't watch new files

Lurker (the library Nova2D uses for hot reload) watches existing files in
`src/`. If you create a new file, the watcher might not detect it. If that happens,
restart `love .`.

---

## Gestor / Dependencies

### "No such file or directory" in gestor

If you run gestor commands from the wrong directory:

```bash
# Correct (from the project root):
love gestor/ install

# Incorrect:
love gestor/install     # missing the slash
```

### "curl" fails with GitHub API rate limit

The gestor uses the GitHub API to detect versions. There is a limit of 60 requests per
hour for unauthenticated IPs. If you install many dependencies in a row, you might
hit the limit.

Wait an hour or authenticate with `GITHUB_TOKEN` (if the gestor supports it).

### The dependency doesn't download

Verify that:
1. The `repo` in `nova2d.lua` exists on GitHub
2. The `version` (tag) exists in that repo
3. `curl` and `unzip` are installed

Try manually:

```bash
curl -fsSL https://raw.githubusercontent.com/kikito/bump.lua/3.1.7/bump.lua
```

If that works, the issue is not network-related.

### Difference between "single" and "multi"

| type | Description | Example |
|---|---|---|
| `"single"` | A single `.lua` file | `bump.lua` — direct download |
| `"multi"` | Multiple files in a ZIP | `anim8`, `hump` — download and extract |

If a single-file library has internal dependencies (e.g. it requires other local
files), it won't work correctly as single.

---

## Migration / Concepts

### I'm coming from pure Love2D, how do I start?

Nova2D is Love2D with structure. Everything you know about Love2D works:

- `love.graphics`, `love.keyboard`, `love.audio`, etc. are still available
- `main.lua` and `conf.lua` are the same as you would use without a framework
- The difference is that Nova2D splits your code into `states/`, `entities/`, `systems/`,
  `utils/` and handles the state machine for you

Start with the Pong tutorial and adapt it to whatever you want to build.

### What about the require path for my modules?

Nova2D extends `package.path` automatically via `conf.lua` so you can do:

```lua
local Player = require("src.entities.player") -- src/entities/player.lua
local Menu   = require("src.states.menu")     -- src/states/menu.lua
local bump   = require("bump")                -- libs/bump.lua
```

### Can I delete gestor/ for release?

Yes. `gestor/` is a development tool that runs as headless Love2D. It doesn't
affect performance if it's there, but you can safely delete it. The same goes for
`docs/` and `openspec/`.

### How do I update Nova2D to a new version?

Nova2D doesn't have an `update` command yet. The recommended way is:

```bash
# Clone the new version into a different directory
curl -fsSL https://nova2d.pages.dev/install.sh | bash -s my-game-updated

# Copy your src/ and assets/ code to the new project
cp -r my-game/src my-game-updated/
cp -r my-game/assets my-game-updated/

# Install your dependencies
cd my-game-updated
love gestor/ install
```

---

## Compatibility

### What version of Love2D do I need?

Love2D 11.x (tested on 11.4 and 11.5). Older versions (0.10.x) are not compatible
due to API changes in `love.graphics` and `love.filesystem`.

### Does it work on Web (love.js / Wasm)?

Not officially tested. Nova2D uses pure Love2D without native modules, so it should
work with [love.js](https://github.com/TannerRogalsky/love.js/), but there is no
guarantee. Hot reload does not work on Web.

### What about Android?

The frozen `main.lua` and Nova2D's hot reload do not add any additional restrictions.
If your Love2D project compiles for Android, Nova2D should too. Not officially
tested.
