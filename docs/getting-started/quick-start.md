# Quick Start

Get Nova2D running and build a moving player in under 2 minutes.

## Prerequisites

- [Love2D 11.x](https://love2d.org/) installed
- `curl` (comes with Windows 10+, macOS, and most Linux)
- `unzip` (needed for multi-file dependencies — install via your package manager)

## Step 1: Create a project

**Option A — One-command install (recommended):**

```bash
curl -fsSL https://nova2d.dev/install.sh | bash -s my-game
cd my-game
```

> **Windows**: use **Git Bash**, not PowerShell. PowerShell has a built-in `curl` alias
> that maps to `Invoke-WebRequest` and won't work with this script.

**Option B — Manual clone:**

```bash
git clone https://github.com/CyberDevStudios/Nova2d.git my-game
cd my-game
```

## Step 2: Run it

```bash
love .
```

You should see:
1. The Nova2D splash screen with animated logo and particle stars
2. The main menu after 3 seconds (or press any key to skip)
3. Three menu options: New Game, Credits, Quit

## Step 3: Create a player entity

Create `src/entities/player.lua`:

```lua
local Player = {}
Player.__index = Player

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x, self.y = x, y
    self.speed = 200
    return self
end

function Player:update(dt)
    if love.keyboard.isDown("left")  then self.x = self.x - self.speed * dt end
    if love.keyboard.isDown("right") then self.x = self.x + self.speed * dt end
    if love.keyboard.isDown("up")    then self.y = self.y - self.speed * dt end
    if love.keyboard.isDown("down")  then self.y = self.y + self.speed * dt end
end

function Player:draw()
    love.graphics.setColor(0.2, 0.6, 1)
    love.graphics.circle("fill", self.x, self.y, 25)
    love.graphics.setColor(1, 1, 1)
end

return Player
```

`Player.new(x, y)` returns an independent instance; the module itself is never modified.
See [Entities](../core-concepts/entities.md) for the full pattern.

## Step 4: Wire the player into the game state

Open `src/states/game.lua` and replace its contents:

```lua
local Gamestate = require("hump.gamestate")
local EntityManager = require("src.systems.entitymanager")
local Player = require("src.entities.player")

local Game = {}

function Game:enter()
    self.entities = EntityManager.new({ layers = { "actors" } })
    self.player = Player.new(400, 300)
    self.entities:add(self.player, "actors")
end

function Game:update(dt)
    self.entities:update(dt)
end

function Game:draw()
    love.graphics.clear()
    self.entities:draw()
end

function Game:keypressed(key)
    if key == "escape" then
        Gamestate.push(require("src.states.pause"))
    end
end

return Game
```

> The manager calls `enter`, `update`, `draw` and `leave` on each entity. You can also call
> `self.player:update(dt)` directly if you don't need layers, tags or deferred removal.
> See [EntityManager](../api/entity-manager.md).

## Step 5: Run it

```bash
love .
```

Navigate to **New Game** (Enter or click). You should see a blue circle on a dark
background. Move it with the arrow keys. Press Escape to pause.

## Next steps

- [States guide](../core-concepts/states.md) — understand screen management and the 5
  built-in states
- [Entities guide](../core-concepts/entities.md) — game object patterns in depth
- [Tutorial: Pong](../guides/tutorial-pong.md) — build a complete playable game from
  scratch
- Install dependencies: `love gestor/ install`
