# Quick Start

Get Nova2D running and build a moving player in under 2 minutes.

## Prerequisites

- [Love2D 11.x](https://love2d.org/) installed
- `curl` (comes with Windows 10+, macOS, and most Linux)

## Step 1: Create a project

**Option A — One-command install (recommended):**

```bash
curl -fsSL https://nova2d.pages.dev/install.sh | bash -s my-game
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

function Player:enter()
    self.x = 400
    self.y = 300
    self.speed = 200
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
end

return Player
```

## Step 4: Wire the player into the game state

Open `src/states/game.lua` and replace its contents:

```lua
local Gamestate = require("hump.gamestate")
local Player = require("entities.player")

local Game = {}

function Game:enter()
    self.player = {}
    Player:enter(self.player)
end

function Game:update(dt)
    Player:update(self.player, dt)
end

function Game:draw()
    love.graphics.clear()
    Player:draw(self.player)
end

function Game:keyreleased(key)
    if key == "escape" then
        Gamestate.push(require("states.pause"))
    end
end

return Game
```

> `Player:enter(self.player)` passes the empty instance table as `self` inside
> `Player:enter()`. After that call, `self.player` has `x`, `y`, and `speed` set on it.
> See [Entities](../core-concepts/entities.md) for the full explanation.

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
