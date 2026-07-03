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

# Install dependencies (optional — not needed for this tutorial)
love gestor/ install
```

Run `love .` to verify you see the splash screen and menu. If it works, you have
everything you need.

---

## Step 2: The Game placeholder state

The `Game` state is an empty placeholder. Replace it with our Pong skeleton.

Replace the entire content of `src/states/game.lua` with:

```lua
local Gamestate = require("hump.gamestate")
local Menu = require("states.menu")

local Game = {}

function Game:enter()
    love.graphics.setBackgroundColor(0.039, 0.039, 0.059)
end

function Game:draw()
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PONG", 0, 280, 800, "center")
end

function Game:keyreleased(key)
    if key == "escape" then Gamestate.switch(Menu) end
end

return Game
```

**Verify**: run `love .`, navigate to New Game, and you should see "PONG" centered on the
screen. Escape returns to the menu.

---

## Step 3: The player paddle

Each paddle will be a separate entity. Start with the player's.

Create `src/entities/paddle.lua`:

```lua
local Paddle = {}

local WIDTH = 12
local HEIGHT = 80
local SPEED = 400  -- pixels per second (fallback for keyboard)

function Paddle:enter(parent, side)
    -- side: "left" or "right"
    self.side = side or "left"
    self.w = WIDTH
    self.h = HEIGHT

    if self.side == "left" then
        self.x = 30
    else
        self.x = 770
    end
    self.y = 300 - HEIGHT / 2

    self.parent = parent  -- keep a reference to the Game state
end

function Paddle:update(dt)
    -- Mouse tracking in Y
    self.y = love.mouse.getY() - self.h / 2

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

Now update `src/states/game.lua` to use the paddle. Replace the entire content with (note the new `Paddle` entity on line 3):

```lua
local Gamestate = require("hump.gamestate")
local Menu = require("states.menu")
local Paddle = require("entities.paddle")

local Game = {}

function Game:enter()
    self.player = {}
    Paddle:enter(self.player, "left")
end

function Game:update(dt)
    Paddle:update(self.player, dt)
end

function Game:draw()
    love.graphics.clear()
    Paddle:draw(self.player)
end

function Game:keyreleased(key)
    if key == "escape" then Gamestate.switch(Menu) end
end

return Game
```

**Verify**: run `love .`, enter the game. Move your mouse vertically — the white paddle
follows the cursor.

---

## Step 4: The ball

Create `src/entities/ball.lua`:

```lua
local Ball = {}

local SIZE = 10
local SPEED = 300

function Ball:enter(parent)
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

Update `src/states/game.lua` to include the ball. Replace the entire content with (note the new `Ball` entity on line 4):

```lua
local Gamestate = require("hump.gamestate")
local Menu = require("states.menu")
local Paddle = require("entities.paddle")
local Ball = require("entities.ball")

local Game = {}

function Game:enter()
    self.player = {}
    Paddle:enter(self.player, "left")

    self.ball = {}
    Ball:enter(self.ball, self)
end

function Game:update(dt)
    Paddle:update(self.player, dt)
    Ball:update(self.ball, dt)
end

function Game:draw()
    love.graphics.clear()
    Paddle:draw(self.player)
    Ball:draw(self.ball)
end

function Game:keyreleased(key)
    if key == "escape" then Gamestate.switch(Menu) end
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

And add the collision block **inside** `Ball:update(dt)`, **after** the `end` that closes the vertical bounce (`-- Vertical bounce (ceiling and floor)` block) and **before** the `-- If it goes off left or right` comment:

```lua
    -- Inside Ball:update(dt), after vertical bounce
    -- Paddle collision
    if self.parent then
        local p = self.parent.player
        if p and Ball.checkCollision(self.x, self.y, self.size, self.size,
                                      p.x, p.y, p.w, p.h) then
            self.x = p.x + p.w  -- push ball out of paddle
            self.vx = -self.vx  -- reverse horizontal direction
            self.vx = self.vx * 1.05  -- speed up by 5%
            self.vy = self.vy + (love.math.random() - 0.5) * 50  -- add a bit of randomness
        end
    end
```

The full `update()` in Ball should look like this:

```lua
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

    -- Paddle collision
    if self.parent then
        local p = self.parent.player
        if p and Ball.checkCollision(self.x, self.y, self.size, self.size,
                                      p.x, p.y, p.w, p.h) then
            self.x = p.x + p.w
            self.vx = -self.vx
            self.vx = self.vx * 1.05
            self.vy = self.vy + (love.math.random() - 0.5) * 50
        end
    end

    -- Out of bounds
    if self.x < -self.size or self.x > 800 + self.size then
        if self.parent and self.parent.onPoint then
            self.parent:onPoint(self.x < 0 and "right" or "left")
        end
    end
end
```

**Verify**: the ball bounces off the paddle, speeds up each time, and has a touch of
randomness on the bounce.

---

## Step 6: Enemy paddle (AI)

In `src/states/game.lua`, replace the entire `Game:enter()` function with (note the new `self.enemy` block):

```lua
function Game:enter()
    self.player = {}
    Paddle:enter(self.player, "left")

    self.enemy = {}
    Paddle:enter(self.enemy, "right")

    self.ball = {}
    Ball:enter(self.ball, self)
end
```

Then replace the `Game:update(dt)` and `Game:draw()` functions in the same file with:

```lua
function Game:update(dt)
    Paddle:update(self.player, dt)
    Paddle:update(self.enemy, dt)  -- for now it stays still
    Ball:update(self.ball, dt)
end

function Game:draw()
    love.graphics.clear()
    Paddle:draw(self.player)
    Paddle:draw(self.enemy)
    Ball:draw(self.ball)
end
```

**Verify**: there are two paddles, the right one stays still. Now we add AI
behavior. Add this method to `src/entities/paddle.lua`, **after** the `Paddle:update(dt)` function (after the `end` on line 96) and **before** the `Paddle:draw()` function (before `function Paddle:draw()` on line 98):

```lua
function Paddle:aiUpdate(dt, ballY)
    -- The AI chases the ball, but it's not perfect
    local paddleCenter = self.y + self.h / 2
    local diff = ballY - paddleCenter

    if math.abs(diff) > 10 then  -- dead zone to prevent jitter
        local speed = 250  -- a bit slower than the mouse
        self.y = self.y + math.max(-speed, math.min(speed, diff)) * dt
    end

    -- Clamp to screen
    if self.y < 0 then self.y = 0 end
    if self.y > 600 - self.h then self.y = 600 - self.h end
end
```

And in `src/states/game.lua`, inside `Game:update(dt)`, find the line `Paddle:update(self.enemy, dt)` and change it to:

```lua
    Paddle:aiUpdate(self.enemy, dt, self.ball.y)
```

**Verify**: the right paddle chases the ball. It's not perfect — it has a dead
zone so it can be beaten.

---

## Step 7: Score

Add score to the Game state and an `onPoint` method. In `src/states/game.lua`:

- **Replace** `Game:enter()` with the version below (note the `self.playerScore` and `self.enemyScore` at the top)
- **Add** the new `Game:onPoint()` function **after** `Game:enter()` and **before** `Game:update(dt)`

```lua
function Game:enter()
    self.playerScore = 0
    self.enemyScore = 0

    self.player = {}
    Paddle:enter(self.player, "left")

    self.enemy = {}
    Paddle:enter(self.enemy, "right")

    self.ball = {}
    Ball:enter(self.ball, self)
end

function Game:onPoint(scoringSide)
    if scoringSide == "left" then
        self.playerScore = self.playerScore + 1
    else
        self.enemyScore = self.enemyScore + 1
    end
    -- Reset ball
    self.ball = {}
    Ball:enter(self.ball, self)
end
```

Then replace the entire `Game:draw()` function with:

```lua
function Game:draw()
    love.graphics.clear()
    Paddle:draw(self.player)
    Paddle:draw(self.enemy)
    Ball:draw(self.ball)

    -- Score
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.printf(tostring(self.playerScore), 0, 40, 350, "right")
    love.graphics.printf(tostring(self.enemyScore), 0, 40, 450, "left")

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

In `src/states/game.lua`, **inside** `Game:enter()`, **after** `Ball:enter(self.ball, self)` (the last line before the `end`), add:

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

In `src/entities/ball.lua`, **inside** `Ball:update(dt)`, add this block in **two places**:

1. **After** the `end` that closes the vertical bounce block, **before** the paddle collision block
2. **After** the `end` that closes the paddle collision block, **before** the `-- Out of bounds` check

```lua
    if self.parent and self.parent.beep then
        self.parent.beep:stop()
        self.parent.beep:play()
    end
```

> If you don't hear anything, check that `t.modules.audio = false` isn't in your
> `conf.lua`. Nova2D ships with it disabled by default — you need to change it to `true`.

---

## Result

After completing step 7 (without sound), this is what you get:

<div style="text-align: center;">
  <img src="/images/demo-pong.gif" alt="Pong demo gameplay" style="width: 60%;" />
</div>

```
src/
├── states/
│   ├── game.lua        -- Main loop, score, ball
│   ├── splash.lua      -- Unchanged
│   └── menu.lua        -- Unchanged
└── entities/
    ├── paddle.lua      -- Paddle (player mouse + AI)
    └── ball.lua        -- Ball with physics and collisions
```

Complete reference files:

**`src/states/game.lua`**:
```lua
local Gamestate = require("hump.gamestate")
local Menu = require("states.menu")
local Paddle = require("entities.paddle")
local Ball = require("entities.ball")

local Game = {}

function Game:enter()
    self.playerScore = 0
    self.enemyScore = 0

    self.player = {}
    Paddle:enter(self.player, "left")

    self.enemy = {}
    Paddle:enter(self.enemy, "right")

    self.ball = {}
    Ball:enter(self.ball, self)
end

function Game:update(dt)
    Paddle:update(self.player, dt)
    Paddle:aiUpdate(self.enemy, dt, self.ball.y)
    Ball:update(self.ball, dt)
end

function Game:draw()
    love.graphics.clear()
    Paddle:draw(self.player)
    Paddle:draw(self.enemy)
    Ball:draw(self.ball)

    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.printf(tostring(self.playerScore), 0, 40, 350, "right")
    love.graphics.printf(tostring(self.enemyScore), 0, 40, 450, "left")

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
    Ball:enter(self.ball, self)
end

function Game:keyreleased(key)
    if key == "escape" then Gamestate.switch(Menu) end
end

return Game
```

**`src/entities/paddle.lua`**:
```lua
local Paddle = {}

local WIDTH = 12
local HEIGHT = 80

function Paddle:enter(parent, side)
    self.side = side or "left"
    self.w = WIDTH
    self.h = HEIGHT
    if self.side == "left" then self.x = 30 else self.x = 770 end
    self.y = 300 - HEIGHT / 2
    self.parent = parent
end

function Paddle:update(dt)
    self.y = love.mouse.getY() - self.h / 2
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

local SIZE = 10
local SPEED = 300

function Ball.checkCollision(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx
        and ay < by + bh and ay + ah > by
end

function Ball:enter(parent)
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
end

function Ball:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    if self.y <= 0 then
        self.y = 0; self.vy = -self.vy
    elseif self.y >= 600 - self.size then
        self.y = 600 - self.size; self.vy = -self.vy
    end

    if self.parent then
        local p = self.parent.player
        if p and Ball.checkCollision(self.x, self.y, self.size, self.size,
                                      p.x, p.y, p.w, p.h) then
            self.x = p.x + p.w
            self.vx = -self.vx
            self.vx = self.vx * 1.05
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

## Next steps

- Add a power-up that spawns every 10 seconds
- Make the ball speed increase gradually over time
- Add a pause menu with a "Restart" option
- Replace rectangles with sprites (load images from `assets/images/`)
- Sound with Love2D: generate tones or load `.wav`/`.ogg` files
- Use `bump.lua` for more complex collisions: `love gestor/ install bump.lua`
