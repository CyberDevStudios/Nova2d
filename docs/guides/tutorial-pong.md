# Tutorial: Build Pong

Build a complete, playable Pong game with Nova2D. Each step produces a game you can run
and see working — no need to wait until the end.

**Estimated time**: 30-45 minutes.
**Requirements**: Love2D 11.x, Nova2D installed.

This is the finished game running — watch it first, then build it step by step:

<!-- youtube:snyD3X8_B5Q -->

---

## Step 1: Create the project

```bash
curl -fsSL https://nova2d.dev/install.sh | bash -s pong
cd pong
```

Run `love .` to verify you see the splash screen and menu. If it works, you have
everything you need.

---

## Step 2: The Game state

The built-in `Game` state is the platformer demo. Replace it with our Pong skeleton.

Replace the entire content of `src/states/game.lua` with:

```lua
local Gamestate = require("hump.gamestate")
local Menu = require("src.states.menu")
local input = require("src.systems.input")

local Game = {}

function Game:enter()
    love.graphics.setBackgroundColor(0.039, 0.039, 0.059)

    -- Nova2D Input System: bind actions to keys
    self.inp = input.new({ defaultBindings = {
        pause = "escape",
        up    = "up",
        down  = "down",
    }})
end

function Game:update(dt)
    self.inp:update(dt)

    if self.inp:isPressed("pause") then
        Gamestate.switch(Menu)
    end
end

function Game:draw()
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PONG", 0, 280, 800, "center")
end

return Game
```

> **Input System**: no `love.keyreleased`/`love.keypressed` spaghetti for gameplay.
> Bind actions to keys once, then poll `inp:isPressed("action")` in `update()`. Clean,
> portable, and gamepad-ready.

**Verify**: run `love .`, navigate to New Game, and you should see "PONG" centered.
Press Escape to return to the menu.

---

## Step 3: The player paddle

Each paddle is an entity built with the constructor pattern.

Create `src/entities/paddle.lua`:

```lua
local Paddle = {}
Paddle.__index = Paddle

local WIDTH = 12
local HEIGHT = 80
local SPEED = 400

function Paddle.new(side, parent)
    local self = setmetatable({}, Paddle)
    self.side = side or "left"
    self.w = WIDTH
    self.h = HEIGHT
    self.x = (self.side == "left") and 30 or 770
    self.y = 300 - HEIGHT / 2
    self.parent = parent
    return self
end

function Paddle:update(dt, inp)
    if inp:isPressed("up") then
        self.y = self.y - SPEED * dt
    end
    if inp:isPressed("down") then
        self.y = self.y + SPEED * dt
    end

    -- Clamp to screen
    if self.y < 0 then self.y = 0 end
    if self.y > 600 - self.h then self.y = 600 - self.h end
end

function Paddle:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Paddle
```

Now update `src/states/game.lua`:

```lua
local Gamestate = require("hump.gamestate")
local Menu = require("src.states.menu")
local input = require("src.systems.input")
local Paddle = require("src.entities.paddle")

local Game = {}

function Game:enter()
    self.player = Paddle.new("left")

    self.inp = input.new({ defaultBindings = {
        pause = "escape",
        up    = "up",
        down  = "down",
    }})
end

function Game:update(dt)
    self.inp:update(dt)

    if self.inp:isPressed("pause") then
        Gamestate.switch(Menu)
    end

    self.player:update(dt, self.inp)
end

function Game:draw()
    love.graphics.clear()
    self.player:draw()
end

return Game
```

**Verify**: run `love .`, enter the game. Press UP and DOWN — the white paddle moves.
Escape returns to the menu.

---

## Step 4: The ball

Create `src/entities/ball.lua`:

```lua
local Ball = {}
Ball.__index = Ball

local SIZE = 10
local SPEED = 300

function Ball.new(parent)
    local self = setmetatable({}, Ball)
    self.x = 400 - SIZE / 2
    self.y = 300 - SIZE / 2
    self.size = SIZE
    self.parent = parent

    -- Random initial direction
    local angle = math.random() * math.pi * 2
    self.vx = math.cos(angle) * SPEED
    self.vy = math.sin(angle) * SPEED

    -- Make sure it doesn't go perfectly horizontal
    if math.abs(self.vx) < SPEED * 0.3 then
        self.vx = (self.vx >= 0 and 1 or -1) * SPEED * 0.3
    end

    return self
end

function Ball:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Vertical bounce (ceiling and floor)
    if self.y <= 0 then
        self.y = 0
        self.vy = -self.vy
    elseif self.y >= 600 - self.size then
        self.y = 600 - self.size
        self.vy = -self.vy
    end

    -- If it goes off left or right, notify the state
    if self.x < -self.size or self.x > 800 + self.size then
        if self.parent and self.parent.onPoint then
            self.parent:onPoint(self.x < 0 and "right" or "left")
        end
    end
end

function Ball:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.size, self.size)
end

return Ball
```

Update `src/states/game.lua`:

```lua
local Gamestate = require("hump.gamestate")
local Menu = require("src.states.menu")
local input = require("src.systems.input")
local Paddle = require("src.entities.paddle")
local Ball = require("src.entities.ball")

local Game = {}

function Game:enter()
    self.player = Paddle.new("left")
    self.ball = Ball.new(self)

    self.inp = input.new({ defaultBindings = {
        pause = "escape",
        up    = "up",
        down  = "down",
    }})
end

function Game:update(dt)
    self.inp:update(dt)

    if self.inp:isPressed("pause") then
        Gamestate.switch(Menu)
    end

    self.player:update(dt, self.inp)
    self.ball:update(dt)
end

function Game:draw()
    love.graphics.clear()
    self.player:draw()
    self.ball:draw()
end

return Game
```

> We pass `self` (the Game state) as the ball's `parent`, so the ball can call
> `self.parent:onPoint()` when someone scores.

**Verify**: the ball bounces off the ceiling and floor. When it goes off the sides, the
console shows an error (`onPoint` doesn't exist yet) — that's normal, we'll add it later.

---

## Step 5: Paddle-ball collision

We add manual AABB (axis-aligned bounding box) collision detection, without external
libraries. This works for any pair of rectangles.

Add this function at the end of `src/entities/ball.lua` (before `return Ball`):

```lua
function Ball.checkCollision(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw
        and ax + aw > bx
        and ay < by + bh
        and ay + ah > by
end
```

Then add the collision block inside `Ball:update(dt)`, after the vertical bounce and
before the out-of-bounds check:

```lua
    -- Paddle collisions (check BOTH paddles)
    if self.parent then
        -- Bounce off player paddle (left side)
        local p = self.parent.player
        if p and Ball.checkCollision(self.x, self.y, self.size, self.size,
                                     p.x, p.y, p.w, p.h) then
            self.x = p.x + p.w              -- push the ball out
            self.vx = -self.vx * 1.05       -- reverse and speed up 5%
            self.vy = self.vy + (love.math.random() - 0.5) * 50
        end

        -- Bounce off enemy paddle (right side)
        local e = self.parent.enemy
        if e and Ball.checkCollision(self.x, self.y, self.size, self.size,
                                     e.x, e.y, e.w, e.h) then
            self.x = e.x - self.size
            self.vx = -self.vx * 1.05
            self.vy = self.vy + (love.math.random() - 0.5) * 50
        end
    end
```

**Verify**: the ball bounces off the player paddle, speeds up each time, and has a touch
of randomness on the bounce.

---

## Step 6: Enemy paddle (AI)

In `src/states/game.lua`, add the enemy in `Game:enter()`:

```lua
function Game:enter()
    self.player = Paddle.new("left")
    self.enemy = Paddle.new("right")
    self.ball = Ball.new(self)

    self.inp = input.new({ defaultBindings = {
        pause = "escape",
        up    = "up",
        down  = "down",
    }})
end
```

Then update `Game:update(dt)` and `Game:draw()`:

```lua
function Game:update(dt)
    self.inp:update(dt)

    if self.inp:isPressed("pause") then
        Gamestate.switch(Menu)
    end

    self.player:update(dt, self.inp)
    self.enemy:update(dt)          -- stays still for now
    self.ball:update(dt)
end

function Game:draw()
    love.graphics.clear()
    self.player:draw()
    self.enemy:draw()
    self.ball:draw()
end
```

**Verify**: there are two paddles; the right one stays still.

Now add the AI method to `src/entities/paddle.lua`, after `Paddle:update`:

```lua
function Paddle:aiUpdate(dt, ballY)
    -- The AI chases the ball, but it's not perfect
    local paddleCenter = self.y + self.h / 2
    local diff = ballY - paddleCenter

    if math.abs(diff) > 10 then        -- dead zone to prevent jitter
        local speed = 250              -- slower than the player
        self.y = self.y + math.max(-speed, math.min(speed, diff)) * dt
    end

    if self.y < 0 then self.y = 0 end
    if self.y > 600 - self.h then self.y = 600 - self.h end
end
```

In `Game:update(dt)`, replace `self.enemy:update(dt)` with:

```lua
    self.enemy:aiUpdate(dt, self.ball.y)
```

**Verify**: the right paddle chases the ball. It's not perfect — it has a dead zone, so
it can be beaten.

---

## Step 7: Score

Add score to the Game state and an `onPoint` method:

```lua
function Game:enter()
    self.playerScore = 0
    self.enemyScore = 0

    self.player = Paddle.new("left")
    self.enemy = Paddle.new("right")
    self.ball = Ball.new(self)

    self.inp = input.new({ defaultBindings = {
        pause = "escape",
        up    = "up",
        down  = "down",
    }})

    -- Create fonts ONCE (not every draw frame)
    self.fontScore = love.graphics.newFont(48)
end

function Game:onPoint(scoringSide)
    if scoringSide == "left" then
        self.playerScore = self.playerScore + 1
    else
        self.enemyScore = self.enemyScore + 1
    end

    self.ball = Ball.new(self)
end
```

Then replace `Game:draw()`:

```lua
function Game:draw()
    love.graphics.clear()
    self.player:draw()
    self.enemy:draw()
    self.ball:draw()

    -- Score (large font, centered on each half)
    love.graphics.setFont(self.fontScore)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.printf(tostring(self.playerScore), 0, 40, 380, "right")
    love.graphics.printf(tostring(self.enemyScore), 420, 40, 380, "left")

    -- Dotted center line
    for y = 0, 600, 20 do
        love.graphics.rectangle("fill", 399, y, 2, 10)
    end
end
```

**Verify**: the score updates when the ball goes off. The ball resets to the center after
each point.

---

## Step 8: Sound (optional)

Add simple sound effects generated with Love2D (no external files). In `src/states/game.lua`,
inside `Game:enter()`, after `Ball.new(self)`:

```lua
    -- Generate a procedural beep
    local sampleRate = 44100
    local beepData = love.sound.newSoundData(2000, sampleRate)
    for i = 0, 1999 do
        local t = i / sampleRate
        beepData:setSample(i, math.sin(t * 800 * math.pi * 2) * 0.3)
    end
    self.beep = love.audio.newSource(beepData, "static")
```

In `src/entities/ball.lua`, inside `Ball:update(dt)`, add this in two places: after the
vertical bounce and after the paddle collision block:

```lua
    if self.parent and self.parent.beep then
        self.parent.beep:stop()
        self.parent.beep:play()
    end
```

> If you don't hear anything, check `conf.lua`. Nova2D ships with `t.modules.audio = false`;
> change it to `true` to use audio.

---

## Result

After completing step 7 (without sound), this is what you get —
[watch the final run on YouTube](https://www.youtube.com/watch?v=snyD3X8_B5Q).

```
src/
├── states/
│   ├── game.lua        -- Main loop, score, ball
│   ├── splash.lua      -- Unchanged
│   └── menu.lua        -- Unchanged
└── entities/
    ├── paddle.lua      -- Paddle (player keyboard + AI)
    └── ball.lua        -- Ball with physics and collisions
```

Complete reference files:

**`src/entities/paddle.lua`**:

```lua
local Paddle = {}
Paddle.__index = Paddle

local WIDTH = 12
local HEIGHT = 80
local SPEED = 400

function Paddle.new(side, parent)
    local self = setmetatable({}, Paddle)
    self.side = side or "left"
    self.w = WIDTH
    self.h = HEIGHT
    self.x = (self.side == "left") and 30 or 770
    self.y = 300 - HEIGHT / 2
    self.parent = parent
    return self
end

function Paddle:update(dt, inp)
    if inp:isPressed("up") then
        self.y = self.y - SPEED * dt
    end
    if inp:isPressed("down") then
        self.y = self.y + SPEED * dt
    end

    if self.y < 0 then self.y = 0 end
    if self.y > 600 - self.h then self.y = 600 - self.h end
end

function Paddle:aiUpdate(dt, ballY)
    local paddleCenter = self.y + self.h / 2
    local diff = ballY - paddleCenter

    if math.abs(diff) > 10 then
        local speed = 250
        self.y = self.y + math.max(-speed, math.min(speed, diff)) * dt
    end

    if self.y < 0 then self.y = 0 end
    if self.y > 600 - self.h then self.y = 600 - self.h end
end

function Paddle:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Paddle
```

**`src/entities/ball.lua`**:

```lua
local Ball = {}
Ball.__index = Ball

local SIZE = 10
local SPEED = 300

function Ball.new(parent)
    local self = setmetatable({}, Ball)
    self.x = 400 - SIZE / 2
    self.y = 300 - SIZE / 2
    self.size = SIZE
    self.parent = parent

    local angle = math.random() * math.pi * 2
    self.vx = math.cos(angle) * SPEED
    self.vy = math.sin(angle) * SPEED

    if math.abs(self.vx) < SPEED * 0.3 then
        self.vx = (self.vx >= 0 and 1 or -1) * SPEED * 0.3
    end

    return self
end

function Ball.checkCollision(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw
        and ax + aw > bx
        and ay < by + bh
        and ay + ah > by
end

function Ball:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    if self.y <= 0 then
        self.y = 0
        self.vy = -self.vy
    elseif self.y >= 600 - self.size then
        self.y = 600 - self.size
        self.vy = -self.vy
    end

    if self.parent then
        local p = self.parent.player
        if p and Ball.checkCollision(self.x, self.y, self.size, self.size,
                                     p.x, p.y, p.w, p.h) then
            self.x = p.x + p.w
            self.vx = -self.vx * 1.05
            self.vy = self.vy + (love.math.random() - 0.5) * 50
        end

        local e = self.parent.enemy
        if e and Ball.checkCollision(self.x, self.y, self.size, self.size,
                                     e.x, e.y, e.w, e.h) then
            self.x = e.x - self.size
            self.vx = -self.vx * 1.05
            self.vy = self.vy + (love.math.random() - 0.5) * 50
        end
    end

    if self.x < -self.size or self.x > 800 + self.size then
        if self.parent and self.parent.onPoint then
            self.parent:onPoint(self.x < 0 and "right" or "left")
        end
    end
end

function Ball:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.size, self.size)
end

return Ball
```

**`src/states/game.lua`**:

```lua
local Gamestate = require("hump.gamestate")
local Menu = require("src.states.menu")
local input = require("src.systems.input")
local Paddle = require("src.entities.paddle")
local Ball = require("src.entities.ball")

local Game = {}

function Game:enter()
    self.playerScore = 0
    self.enemyScore = 0

    self.player = Paddle.new("left")
    self.enemy = Paddle.new("right")
    self.ball = Ball.new(self)

    self.inp = input.new({ defaultBindings = {
        pause = "escape",
        up    = "up",
        down  = "down",
    }})

    self.fontScore = love.graphics.newFont(48)
end

function Game:onPoint(scoringSide)
    if scoringSide == "left" then
        self.playerScore = self.playerScore + 1
    else
        self.enemyScore = self.enemyScore + 1
    end

    self.ball = Ball.new(self)
end

function Game:update(dt)
    self.inp:update(dt)

    if self.inp:isPressed("pause") then
        Gamestate.switch(Menu)
    end

    self.player:update(dt, self.inp)
    self.enemy:aiUpdate(dt, self.ball.y)
    self.ball:update(dt)
end

function Game:draw()
    love.graphics.clear()
    self.player:draw()
    self.enemy:draw()
    self.ball:draw()

    love.graphics.setFont(self.fontScore)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.printf(tostring(self.playerScore), 0, 40, 380, "right")
    love.graphics.printf(tostring(self.enemyScore), 420, 40, 380, "left")

    for y = 0, 600, 20 do
        love.graphics.rectangle("fill", 399, y, 2, 10)
    end
end

return Game
```

## Next steps

- [Entities](../core-concepts/entities.md) — the constructor pattern in depth
- [EntityManager](../api/entity-manager.md) — layers, tags and deferred removal
- [Platformer tutorial](tutorial-platformer.md) — the built-in demo explained
