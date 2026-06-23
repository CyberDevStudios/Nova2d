# Tutorial: 5-Minute Game

Build a simple moving circle game in 5 minutes.

## Step 1: Create a project

```bash
git clone https://github.com/CyberDevStudios/Nova2d.git my-game
cd my-game
```

## Step 2: Create a player entity

Create `src/entities/player.lua`:

```lua
local Player = {}

function Player:enter()
    self.x = 400
    self.y = 300
    self.speed = 200
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
end

return Player
```

## Step 3: Add the player to the game state

Edit `src/states/game.lua`:

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
    Player:draw(self.player)
end

function Game:keyreleased(key)
    if key == "escape" then
        Gamestate.push(require("states.pause"))
    end
end

return Game
```

## Step 4: Run it

```bash
love .
```

You should see a blue circle you can move with arrow keys. Press Escape to pause.

## Step 5: Install dependencies (optional)

```bash
love gestor/ install
```

This installs bump.lua for collisions, anim8 for animations, and lovebird for debugging.
