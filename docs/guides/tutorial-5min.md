# Tutorial: 5-Minute Game

Build a simple moving circle game in 5 minutes.

## Step 1: Create a project

```bash
curl -fsSL https://nova2d.dev/install.sh | bash -s my-game
cd my-game
```

Or clone the repository manually:

```bash
git clone https://github.com/CyberDevStudios/Nova2d.git my-game
cd my-game
```

## Step 2: Create a player entity

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
    if love.keyboard.isDown("left") then
        self.x = self.x - self.speed * dt
    elseif love.keyboard.isDown("right") then
        self.x = self.x + self.speed * dt
    end
    if love.keyboard.isDown("up") then
        self.y = self.y - self.speed * dt
    elseif love.keyboard.isDown("down") then
        self.y = self.y + self.speed * dt
    end
end

function Player:draw()
    love.graphics.setColor(0.2, 0.6, 1)
    love.graphics.circle("fill", self.x, self.y, 25)
    love.graphics.setColor(1, 1, 1)
end

return Player
```

## Step 3: Add the player to the game state

Edit `src/states/game.lua`:

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

## Step 4: Run it

```bash
love .
```

Navigate to **New Game**. You should see a blue circle you can move with the arrow keys.
Press Escape to pause.

## Step 5: Install dependencies (optional)

```bash
love gestor/ install
```

This installs bump.lua for collisions, anim8 for animations, and lovebird for debugging.

## Next steps

- [Entities](../core-concepts/entities.md) — the constructor pattern in depth
- [EntityManager](../api/entity-manager.md) — layers, tags and deferred removal
- [Platformer tutorial](tutorial-platformer.md) — the demo explained step by step
