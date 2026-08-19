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
curl -fsSL https://raw.githubusercontent.com/kikito/bump.lua/v3.1.7/bump.lua
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
local bump   = require("bump")                -- libs/bump/bump.lua
```

### Can I delete gestor/ for release?

Yes. `gestor/` is a development tool that runs as headless Love2D. It doesn't
affect performance if it's there, but you can safely delete it. The same goes for
`docs/` and `openspec/`.

### How do I update Nova2D to a new version?

Nova2D doesn't have an `update` command yet. The recommended way is:

```bash
# Clone the new version into a different directory
curl -fsSL https://nova2d.dev/install.sh | bash -s my-game-updated

# Copy your src/ and assets/ code to the new project
cp -r my-game/src my-game-updated/
cp -r my-game/assets my-game-updated/

# Install your dependencies
cd my-game-updated
love gestor/ install
```

---

## Core Systems

### My character doesn't jump, what's wrong?

Most likely you forgot to set `jump.grounded` each frame based on your collision logic:

```lua
function love.update(dt)
    -- Your collision detection...
    jump.grounded = myCollision.isOnGround
    jump:update(dt)
end
```

The jump system does NOT auto-detect ground — you must set `grounded = true` when your player is touching a platform. Also make sure you call `jump:jump()` on input and `jump:release()` on key release (for variable height).

### How do multi-jumps work?

Configure `maxJumps` in the config:

```lua
local jump = require("src.systems.jump").new({ maxJumps = 2 })
```

Each time the player lands, the jump counter resets. While airborne, they can jump up to `maxJumps` times. Single jump (`maxJumps = 1`) is the default.

### How long do i-frames last after taking damage?

By default, 1 second. Configure it:

```lua
local health = require("src.systems.health").new({ iFrameDuration = 2.0 })
```

The i-frame timer counts down in `update(dt)`. While invincible, `takeDamage()` is a no-op and the `iFramesStart`/`iFramesEnd` events fire on transition.

### How do I know if the player is dead?

Check `health:isDead()` or listen for the `died()` event:

```lua
health:on("died", function()
    -- show game over screen
end)
```

Once dead, all operations (damage, heal, events) are locked until you call `health:reset()`.

### How do I loop a timer as a countdown?

The timer fires `expired()` once. To loop, reset it in the callback:

```lua
local t = require("src.systems.timer").new({ duration = 5, mode = "countdown" })
t:on("expired", function()
    t:reset()  -- restart
end)
```

For stopwatch mode, set `mode = "stopwatch"` — it counts up from 0 instead of down from duration.

### Why is my camera not following the player?

Make sure you:
1. Call `camera:follow(player)` with a table that has `.x` and `.y`
2. Call `camera:update(dt)` in your `love.update()`
3. Wrap your draw calls with `attach()`/`detach()`:

```lua
function love.draw()
    camera:attach()
    -- draw everything here (player, enemies, map)
    camera:detach()
    -- draw HUD here (not affected by camera)
end
```

### The camera shake doesn't work

`startShake(intensity, duration)` decays over time. Make sure intensity is high enough for the effect to be visible:

```lua
camera:startShake(10, 0.5)  -- 10 pixels, 0.5 seconds
```

Also verify that `camera:update(dt)` is called every frame.

### Can I use love.keypressed with the Input system?

**No.** The Input system hooks `love.keypressed` internally to capture press timestamps for the buffer. Your gameplay logic must use `isPressed()` / `isBuffered()` in `love.update()` instead.

If you need `love.keypressed` for non-gameplay purposes (e.g., toggling fullscreen), define it BEFORE calling `input.new()` — the system chains to it automatically.

### How do I remap keys at runtime?

```lua
-- Replace jump binding with a single key
inp:rebind("jump", "space")

-- Add a secondary key (jump also responds to up)
inp:bind("jump", "up")
```

Call `bind()` to add keys, `rebind()` to replace all bindings for an action, and `unbind(action, key)` to remove a specific key.

### My animation stays on the first frame

Make sure you call `animation:update(dt)` in `love.update()` AND start playback with `play()` after creating it:

```lua
local anim = require("src.systems.animation").new({
    image = playerImage, frameWidth = 32, frameHeight = 32, frames = { 1, 2, 3, 4 },
})
anim:play()

function love.update(dt)
    anim:update(dt)
end
```

A new animation starts paused on frame 1 — without `play()` it never advances. Also verify the `frames` indices match your sprite-sheet grid (1-based, row-major).

### How do I play an animation once and stop?

Set `loop = false` and listen for `complete`:

```lua
local anim = require("src.systems.animation").new({
    image = playerImage, frameWidth = 32, frameHeight = 32, frames = { 1, 2, 3, 4 },
    loop = false,
})
anim:on("complete", function()
    -- e.g. destroy the explosion entity
end)
```

With `loop = false` the animation plays through and fires `complete` exactly once; `update(dt)` then no-ops until you call `play()` again.

### How do I flip my sprite?

Use `flipX` / `flipY` in the config:

```lua
local anim = require("src.systems.animation").new({
    image = playerImage, frameWidth = 32, frameHeight = 32, frames = { 1, 2 },
    flipX = true,  -- face left
})
```

To flip at runtime based on movement direction, mutate the fields directly: `anim.flipX = movingLeft`.

### How do I draw the current frame?

`getQuad()` returns an anim8 Quad ready for `love.graphics.draw`:

```lua
function love.draw()
    love.graphics.draw(anim.image, anim:getQuad(), x, y)
end
```

Use `getDimensions()` for the frame size (e.g. to center the sprite) and `getFrame()` for the current 1-based frame index.

### I don't hear any sound

Nova2D disables the audio module by default in `conf.lua` to improve startup time — enable it first:

```lua
t.modules.audio = true   -- change from false to true
```

Then make sure you create the audio manager and that the source is loaded:

```lua
local audio = require("src.systems.audio").new()
local sfx = love.audio.newSource("assets/sounds/jump.wav", "static")
audio:play("sfx", sfx)
```

Also verify the volume chain: `setMasterVolume()` × channel volume × the per-play `options.volume` all multiply together — any of them at 0 silences the sound.

### How do I play music that doesn't overlap itself?

Use `music()` (single-track semantics) instead of `play()`: it stops whatever is playing on the channel first:

```lua
local audio = require("src.systems.audio").new()
audio:music("music", musicSource)
```

The default `music` channel has `pool = 1` — a second `music()` call replaces the current track. `play()` is for overlapping sound effects (pooled with least-recently-used slot stealing).

### How do I fade audio in or out?

`fade(channel, target, duration)` animates the channel volume:

```lua
audio:fade("music", 0, 2)  -- fade out over 2 seconds
audio:on("fade-complete", function(channel, target)
    if target == 0 then
        audio:stop(channel)  -- fully stopped after fading out
    end
end)
```

Call `audio:update(dt)` in `love.update()` — fades and `ended` detection are driven from it.

### How do I know when a sound finished playing?

Listen for the `ended` event (channel, source):

```lua
audio:on("ended", function(channel, source)
    -- e.g. advance a dialogue queue
end)
```

The audio system polls playing slots in `update(dt)` — don't forget to call it, or `ended` never fires.

### My player passes through walls

`move()` returns the resolved position — you must write it back (or use the system's automatic write-back). Verify the entity is in the world AND you use the returned coordinates:

```lua
local world = require("src.systems.collision").new()

function love.update(dt)
    local actualX, actualY, collided = world:move(player, player.x + vx * dt, player.y + vy * dt)
    if not collided then
        player.x, player.y = actualX, actualY
    end
end
```

The system writes resolved coordinates back into `entity.collider` (or `entity.x/y` when there is no collider) automatically, but if you read `player.x` from a different table than the one you passed to `move()`, you'll see the un-resolved position.

### How do I know what my player collided with?

Listen for the `collision` event — it fires with the other entity and the collision info (normal, touch, overlap):

```lua
world:on("collision", function(entity, other, col)
    if other.tag == "coin" then
        collectCoin(other)
    elseif col.normal.y < 0 then
        -- hit something above (ceiling)
    end
end)
```

`world:check(entity, gx, gy)` is a non-moving probe that returns `true`/`false` for "would collide at that position" — useful for ledge detection before committing a move.

### How do I find entities in an area?

Use `query(x, y, w, h)` for a rectangle and `queryPoint(x, y)` for a point:

```lua
-- enemies within the explosion radius
local hit = world:query(explosion.x - 50, explosion.y - 50, 100, 100)
for _, entity in ipairs(hit) do
    entity:takeDamage(10)
end
```

For pure math checks without a world, the helpers `box()`, `overlaps()`, and `contains()` are available on the module itself.

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
