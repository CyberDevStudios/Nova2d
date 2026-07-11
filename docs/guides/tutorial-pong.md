# Tutorial: Build Pong

Build a complete, playable Pong game using Nova2D. Each step produces a game that
**you can run and see working** — no need to wait until the end to see progress.

**Estimated time**: 30-45 minutes.
**Requirements**: Love2D 11.x, Nova2D installed.

---

## Step 1: Create the project

```bash
curl -fsSL https://nova2d.pages.dev/install.sh | bash -s pong
cd pong
```

Run `love .` to verify you see the splash screen and menu. If it works, you have
everything you need.

---

## Step 2: The Game placeholder state

The `Game` state is an empty placeholder. Replace it with our Pong skeleton.

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

    -- Poll the "pause" action each frame
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

> **Input System hot take**: No more `love.keyreleased` or `love.keypressed` spaghetti
> for gameplay logic. You bind actions to keys once, then poll `inp:isPressed("action")`
> in `update()`. Clean, portable, and gamepad-ready.

**Verify**: run `love .`, navigate to New Game, and you should see "PONG" centered on the
screen. Press Escape to return to the menu.

---

## Step 3: The player paddle

Each paddle will be a separate entity. Start with the player's.

Create `src/entities/paddle.lua`:

```lua
local Paddle = {}

local WIDTH = 12
local HEIGHT = 80
local SPEED = 400

-- IMPORTANT: we use DOT syntax for all Paddle functions.
-- The paddle instance is passed explicitly as the first argument.
-- This lets us have MULTIPLE paddles (player + enemy) with independent state.
-- Using COLON syntax (Paddle:enter, self.xxx) would store state on the
-- Paddle module table, making two paddles overwrite each other.

function Paddle.enter(paddle, side, parent)
    -- paddle: the instance table (self.player, self.enemy)
    -- side: "left" or "right" — CRITICAL: must be second param
    -- parent: the Game state (optional, for callbacks)
    paddle.side = side or "left"
    paddle.w = WIDTH
    paddle.h = HEIGHT

    if paddle.side == "left" then
        paddle.x = 30
    else
        paddle.x = 770
    end
    paddle.y = 300 - HEIGHT / 2

    paddle.parent = parent  -- keep a reference to the Game state
end

function Paddle.update(paddle, dt, inp)
    -- Keyboard control via Nova2D Input System
    if inp:isPressed("up") then
        paddle.y = paddle.y - SPEED * dt
    end
    if inp:isPressed("down") then
        paddle.y = paddle.y + SPEED * dt
    end

    -- Clamp to screen
    if paddle.y < 0 then paddle.y = 0 end
    if paddle.y > 600 - paddle.h then paddle.y = 600 - paddle.h end
end

function Paddle.draw(paddle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.w, paddle.h)
end

return Paddle
```

Now update `src/states/game.lua` to use the paddle and pass the input instance. Replace the entire content with:

```lua
local Gamestate = require("hump.gamestate")
local Menu = require("src.states.menu")
local input = require("src.systems.input")
local Paddle = require("src.entities.paddle")

local Game = {}

function Game:enter()
    self.player = {}
    Paddle.enter(self.player, "left")

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

    -- Pass input instance to paddle for keyboard control
    Paddle.update(self.player, dt, self.inp)
end

function Game:draw()
    love.graphics.clear()
    Paddle.draw(self.player)
end

return Game
```

**Verify**: run `love .`, enter the game. Press UP and DOWN arrows — the white paddle
moves. Escape still returns to the menu.

---

## Step 4: The ball

Create `src/entities/ball.lua`:

```lua
local Ball = {}

local SIZE = 10
local SPEED = 300

-- DOT syntax so each ball instance has its own state.
-- The ball table is passed explicitly as the first argument.

function Ball.enter(ball, parent)
    ball.x = 400 - SIZE / 2
    ball.y = 300 - SIZE / 2
    ball.size = SIZE
    ball.parent = parent

    -- Random initial direction
    local angle = math.random() * math.pi * 2
    ball.vx = math.cos(angle) * SPEED
    ball.vy = math.sin(angle) * SPEED

    -- Make sure it doesn't go perfectly horizontal
    if math.abs(ball.vx) < SPEED * 0.3 then
        ball.vx = (ball.vx >= 0 and 1 or -1) * SPEED * 0.3
    end
end

function Ball.update(ball, dt)
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Vertical bounce (ceiling and floor)
    if ball.y <= 0 then
        ball.y = 0
        ball.vy = -ball.vy
    elseif ball.y >= 600 - ball.size then
        ball.y = 600 - ball.size
        ball.vy = -ball.vy
    end

    -- If it goes off left or right, notify the state
    if ball.x < -ball.size or ball.x > 800 + ball.size then
        if ball.parent and ball.parent.onPoint then
            ball.parent:onPoint(ball.x < 0 and "right" or "left")
        end
    end
end

function Ball.draw(ball)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", ball.x, ball.y, ball.size, ball.size)
end

return Ball
```

Update `src/states/game.lua` to include the ball. Replace the entire content with:

```lua
local Gamestate = require("hump.gamestate")
local Menu = require("src.states.menu")
local input = require("src.systems.input")
local Paddle = require("src.entities.paddle")
local Ball = require("src.entities.ball")

local Game = {}

function Game:enter()
    self.player = {}
    Paddle.enter(self.player, "left")

    self.ball = {}
    Ball.enter(self.ball, self)

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

    Paddle.update(self.player, dt, self.inp)
    Ball.update(self.ball, dt)
end

function Game:draw()
    love.graphics.clear()
    Paddle.draw(self.player)
    Ball.draw(self.ball)
end

return Game
```

> Note that we pass `self` (the Game state) as the ball's `parent`. This way the ball
> can call `self.parent:onPoint()` when someone scores.

**Verify**: the ball bounces off the ceiling and floor. When it goes off the sides, the
console shows an error (`onPoint` doesn't exist yet) — that's normal, we'll add it
later.

---

## Step 5: Paddle-ball collision

We add manual AABB (axis-aligned bounding box) collision detection, without external
libraries. This method works for any pair of rectangles.

Add this function at the end of `src/entities/ball.lua` (before the `return Ball`):

```lua
function Ball.checkCollision(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw
        and ax + aw > bx
        and ay < by + bh
        and ay + ah > by
end
```

And add the collision blocks **inside** `Ball.update(ball, dt)`, **after** the `end` that closes the vertical bounce block and **before** the `-- If it goes off left or right` comment:

```lua
    -- Paddle collisions (check BOTH paddles)
    if ball.parent then
        -- Bounce off player paddle (left side)
        local p = ball.parent.player
        if p and Ball.checkCollision(ball.x, ball.y, ball.size, ball.size,
                                      p.x, p.y, p.w, p.h) then
            ball.x = p.x + p.w  -- push ball out of paddle
            ball.vx = -ball.vx  -- reverse horizontal direction
            ball.vx = ball.vx * 1.05  -- speed up by 5%
            ball.vy = ball.vy + (love.math.random() - 0.5) * 50  -- add a bit of randomness
        end

        -- Bounce off enemy paddle (right side)
        -- (safe to add now — it's ignored until the enemy paddle exists in Step 6)
        local e = ball.parent.enemy
        if e and Ball.checkCollision(ball.x, ball.y, ball.size, ball.size,
                                      e.x, e.y, e.w, e.h) then
            ball.x = e.x - ball.size
            ball.vx = -ball.vx
            ball.vx = ball.vx * 1.05
            ball.vy = ball.vy + (love.math.random() - 0.5) * 50
        end
    end
```

The full `update()` in Ball should look like this:

```lua
function Ball.update(ball, dt)
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Vertical bounce (ceiling and floor)
    if ball.y <= 0 then
        ball.y = 0
        ball.vy = -ball.vy
    elseif ball.y >= 600 - ball.size then
        ball.y = 600 - ball.size
        ball.vy = -ball.vy
    end

    -- Paddle collisions (check BOTH paddles)
    if ball.parent then
        -- Bounce off player paddle (left side)
        local p = ball.parent.player
        if p and Ball.checkCollision(ball.x, ball.y, ball.size, ball.size,
                                      p.x, p.y, p.w, p.h) then
            ball.x = p.x + p.w
            ball.vx = -ball.vx
            ball.vx = ball.vx * 1.05
            ball.vy = ball.vy + (love.math.random() - 0.5) * 50
        end

        -- Bounce off enemy paddle (right side)
        local e = ball.parent.enemy
        if e and Ball.checkCollision(ball.x, ball.y, ball.size, ball.size,
                                      e.x, e.y, e.w, e.h) then
            ball.x = e.x - ball.size
            ball.vx = -ball.vx
            ball.vx = ball.vx * 1.05
            ball.vy = ball.vy + (love.math.random() - 0.5) * 50
        end
    end

    -- Out of bounds
    if ball.x < -ball.size or ball.x > 800 + ball.size then
        if ball.parent and ball.parent.onPoint then
            ball.parent:onPoint(ball.x < 0 and "right" or "left")
        end
    end
end
```

**Verify**: the ball bounces off BOTH paddles, speeds up each time, and has a touch of
randomness on the bounce.

---

## Step 6: Enemy paddle (AI)

In `src/states/game.lua`, replace the entire `Game:enter()` function with (note the new `self.enemy` block):

```lua
function Game:enter()
    self.player = {}
    Paddle.enter(self.player, "left")

    self.enemy = {}
    Paddle.enter(self.enemy, "right")

    self.ball = {}
    Ball.enter(self.ball, self)

    self.inp = input.new({ defaultBindings = {
        pause = "escape",
        up    = "up",
        down  = "down",
    }})
end
```

Then replace the `Game:update(dt)` and `Game:draw()` functions in the same file with:

```lua
function Game:update(dt)
    self.inp:update(dt)

    if self.inp:isPressed("pause") then
        Gamestate.switch(Menu)
    end

    Paddle.update(self.player, dt, self.inp)
    Paddle.update(self.enemy, dt)  -- for now it stays still
    Ball.update(self.ball, dt)
end

function Game:draw()
    love.graphics.clear()
    Paddle.draw(self.player)
    Paddle.draw(self.enemy)
    Ball.draw(self.ball)
end
```

**Verify**: there are two paddles, the right one stays still. Now we add AI
behavior. Add this method to `src/entities/paddle.lua`, **after** the `Paddle.update(paddle, dt)` function and **before** the `Paddle.draw(paddle)` function:

```lua
function Paddle.aiUpdate(paddle, dt, ballY)
    -- The AI chases the ball, but it's not perfect
    local paddleCenter = paddle.y + paddle.h / 2
    local diff = ballY - paddleCenter

    if math.abs(diff) > 10 then  -- dead zone to prevent jitter
        local speed = 250  -- a bit slower than the mouse
        paddle.y = paddle.y + math.max(-speed, math.min(speed, diff)) * dt
    end

    -- Clamp to screen
    if paddle.y < 0 then paddle.y = 0 end
    if paddle.y > 600 - paddle.h then paddle.y = 600 - paddle.h end
end
```

And in `src/states/game.lua`, inside `Game:update(dt)`, find the line `Paddle.update(self.enemy, dt)` and change it to:

```lua
    Paddle.aiUpdate(self.enemy, dt, self.ball.y)
```

**Verify**: the right paddle chases the ball. It's not perfect — it has a dead
zone so it can be beaten.

---

## Step 7: Score

Add score to the Game state and an `onPoint` method. In `src/states/game.lua`:

- **Replace** `Game:enter()` with the version below (note the `self.playerScore` and `self.enemyScore` at the top and the input instance)
- **Add** the new `Game:onPoint()` function **after** `Game:enter()` and **before** `Game:update(dt)`

```lua
function Game:enter()
    self.playerScore = 0
    self.enemyScore = 0

    self.player = {}
    Paddle.enter(self.player, "left")

    self.enemy = {}
    Paddle.enter(self.enemy, "right")

    self.ball = {}
    Ball.enter(self.ball, self)

    self.inp = input.new({ defaultBindings = {
        pause = "escape",
        up    = "up",
        down  = "down",
    }})
end

function Game:onPoint(scoringSide)
    if scoringSide == "left" then
        self.playerScore = self.playerScore + 1
    else
        self.enemyScore = self.enemyScore + 1
    end
    -- Reset ball
    self.ball = {}
    Ball.enter(self.ball, self)
end
```

Then replace the entire `Game:draw()` function with:

```lua
function Game:draw()
    love.graphics.clear()
    Paddle.draw(self.player)
    Paddle.draw(self.enemy)
    Ball.draw(self.ball)

    -- Score (large font, centered on each half)
    love.graphics.setNewFont(48)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.printf(tostring(self.playerScore), 0, 40, 380, "right")
    love.graphics.printf(tostring(self.enemyScore), 420, 40, 380, "left")

    -- Dotted center line
    for y = 0, 600, 20 do
        love.graphics.rectangle("fill", 399, y, 2, 10)
    end
end
```

**Verify**: the score updates when the ball goes off. The ball resets to the
center after each point.

---

## Step 8: Sound (optional)

Add simple sound effects generated with Love2D (no external files):

In `src/states/game.lua`, **inside** `Game:enter()`, **after** `Ball.enter(self.ball, self)` (the last line before the `end`), add:

```lua
    -- Generate procedural sounds
    local sampleRate = 44100
    local beepData = love.sound.newSoundData(2000, sampleRate)
    for i = 0, 1999 do
        local t = i / sampleRate
        beepData:setSample(i, math.sin(t * 800 * math.pi * 2) * 0.3)
    end
    self.beep = love.audio.newSource(beepData, "static")
```

In `src/entities/ball.lua`, **inside** `Ball.update(ball, dt)`, add this block in **two places**:

1. **After** the `end` that closes the vertical bounce block, **before** the paddle collision block
2. **After** the `end` that closes the paddle collision block, **before** the `-- Out of bounds` check

```lua
    if ball.parent and ball.parent.beep then
        ball.parent.beep:stop()
        ball.parent.beep:play()
    end
```

> If you don't hear anything, check that `t.modules.audio = false` isn't in your
> `conf.lua`. Nova2D ships with it disabled by default — you need to change it to `true`.

---

## Result

After completing step 7 (without sound), this is what you get:

<!-- youtube:snyD3X8_B5Q -->

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

    self.player = {}
    Paddle.enter(self.player, "left")

    self.enemy = {}
    Paddle.enter(self.enemy, "right")

    self.ball = {}
    Ball.enter(self.ball, self)

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

    Paddle.update(self.player, dt, self.inp)
    Paddle.aiUpdate(self.enemy, dt, self.ball.y)
    Ball.update(self.ball, dt)
end

function Game:draw()
    love.graphics.clear()
    Paddle.draw(self.player)
    Paddle.draw(self.enemy)
    Ball.draw(self.ball)

    love.graphics.setNewFont(48)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.printf(tostring(self.playerScore), 0, 40, 380, "right")
    love.graphics.printf(tostring(self.enemyScore), 420, 40, 380, "left")

    for y = 0, 600, 20 do
        love.graphics.rectangle("fill", 399, y, 2, 10)
    end
end

function Game:onPoint(scoringSide)
    if scoringSide == "left" then
        self.playerScore = self.playerScore + 1
    else
        self.enemyScore = self.enemyScore + 1
    end
    self.ball = {}
    Ball.enter(self.ball, self)
end

return Game
```

**`src/entities/paddle.lua`**:
```lua
local Paddle = {}

local WIDTH = 12
local HEIGHT = 80
local SPEED = 400

-- IMPORTANT: DOT syntax so each paddle call passes the instance explicitly.
-- This lets player and enemy paddles have independent state.

function Paddle.enter(paddle, side, parent)
    paddle.side = side or "left"
    paddle.w = WIDTH
    paddle.h = HEIGHT
    if paddle.side == "left" then paddle.x = 30 else paddle.x = 770 end
    paddle.y = 300 - HEIGHT / 2
    paddle.parent = parent
end

function Paddle.update(paddle, dt, inp)
    -- Keyboard control via Nova2D Input System
    if inp:isPressed("up") then
        paddle.y = paddle.y - SPEED * dt
    end
    if inp:isPressed("down") then
        paddle.y = paddle.y + SPEED * dt
    end
    if paddle.y < 0 then paddle.y = 0 end
    if paddle.y > 600 - paddle.h then paddle.y = 600 - paddle.h end
end

function Paddle.aiUpdate(paddle, dt, ballY)
    local paddleCenter = paddle.y + paddle.h / 2
    local diff = ballY - paddleCenter
    if math.abs(diff) > 10 then
        local speed = 250
        paddle.y = paddle.y + math.max(-speed, math.min(speed, diff)) * dt
    end
    if paddle.y < 0 then paddle.y = 0 end
    if paddle.y > 600 - paddle.h then paddle.y = 600 - paddle.h end
end

function Paddle.draw(paddle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.w, paddle.h)
end

return Paddle
```

**`src/entities/ball.lua`**:
```lua
local Ball = {}

local SIZE = 10
local SPEED = 300

function Ball.checkCollision(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx
        and ay < by + bh and ay + ah > by
end

function Ball.enter(ball, parent)
    ball.x = 400 - SIZE / 2
    ball.y = 300 - SIZE / 2
    ball.size = SIZE
    ball.parent = parent

    local angle = math.random() * math.pi * 2
    ball.vx = math.cos(angle) * SPEED
    ball.vy = math.sin(angle) * SPEED
    if math.abs(ball.vx) < SPEED * 0.3 then
        ball.vx = (ball.vx >= 0 and 1 or -1) * SPEED * 0.3
    end
end

function Ball.update(ball, dt)
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    if ball.y <= 0 then
        ball.y = 0; ball.vy = -ball.vy
    elseif ball.y >= 600 - ball.size then
        ball.y = 600 - ball.size; ball.vy = -ball.vy
    end

    if ball.parent then
        local p = ball.parent.player
        if p and Ball.checkCollision(ball.x, ball.y, ball.size, ball.size,
                                      p.x, p.y, p.w, p.h) then
            ball.x = p.x + p.w
            ball.vx = -ball.vx
            ball.vx = ball.vx * 1.05
            ball.vy = ball.vy + (love.math.random() - 0.5) * 50
        end

        local e = ball.parent.enemy
        if e and Ball.checkCollision(ball.x, ball.y, ball.size, ball.size,
                                      e.x, e.y, e.w, e.h) then
            ball.x = e.x - ball.size
            ball.vx = -ball.vx
            ball.vx = ball.vx * 1.05
            ball.vy = ball.vy + (love.math.random() - 0.5) * 50
        end
    end

    if ball.x < -ball.size or ball.x > 800 + ball.size then
        if ball.parent and ball.parent.onPoint then
            ball.parent:onPoint(ball.x < 0 and "right" or "left")
        end
    end
end

function Ball.draw(ball)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", ball.x, ball.y, ball.size, ball.size)
end

return Ball
```

## Next steps — go further with Nova2D systems

Now that you know the basics, here are concrete challenges using the other Nova2D systems.

### Timer: power-up every 10 seconds

Use `src.systems.timer` to spawn a power-up every 10 seconds:

```lua
local timer = require("src.systems.timer")

function Game:enter()
    -- ... existing setup ...
    self.powerUpTimer = timer.new({ duration = 10 })
    self.powerUpTimer:on("expired", function()
        -- Spawn power-up at random position
        self.powerUp = {
            x = math.random(100, 700),
            y = math.random(50, 550),
            active = true,
        }
        self.powerUpTimer:reset()  -- restart for next cycle
    end)
end

function Game:update(dt)
    self.powerUpTimer:update(dt)
    -- ... rest of update ...
end
```

### Health: lives system

Replace the flat score with `src.systems.health` for lives. Each point scored
against you costs one life. Three lives and it's game over:

```lua
local health = require("src.systems.health")

function Game:enter()
    self.playerHealth = health.new({ maxHp = 3, iFrameDuration = 1.5 })
    self.playerHealth:on("died", function()
        -- Show game over screen, then reset
    end)
end

-- When opponent scores: self.playerHealth:takeDamage(1, "goal")
```

### More ideas

- **Paddle speed boost**: timer for temporary speed multiplier
- **Controls menu**: let the player rebind keys with `input:rebind()`
- **Replace rectangles with sprites**: load images from `assets/images/`
- **Sound**: Love2D procedural tones (see Step 8) or `.wav`/`.ogg` files
- **bump.lua** for complex collisions: install via `love gestor install bump.lua`
