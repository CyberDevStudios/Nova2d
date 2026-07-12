-- Nova2D — Nova Jumper mini-game
-- Uses all v0.6 systems: input, jump, camera, health, timer
-- src/states/game.lua

local Gamestate = require "hump.gamestate"
local Pause     = require("src.states.pause")
local input     = require("src.systems.input")
local jump      = require("src.systems.jump")
local camera    = require("src.systems.camera")
local health    = require("src.systems.health")
local timer     = require("src.systems.timer")

-- ── Constants ────────────────────────────────────────────────────────
local W, H = 800, 600
local GRAVITY = 800
local MOVE_SPEED = 250
local LEVEL_W = 3200
local LEVEL_H = 600

local COLORS = {
    bg      = {0.039, 0.039, 0.059},
    ground  = {0.25, 0.25, 0.40},
    player  = {0.486, 0.227, 0.929},
    enemy   = {0.929, 0.227, 0.227},
    goal    = {0.227, 0.929, 0.486},
    hp      = {0.929, 0.227, 0.227},
    hpBg    = {0.15, 0.15, 0.20},
    coin    = {0.929, 0.800, 0.227},
}

-- ── Level data ───────────────────────────────────────────────────────
local platforms = {
    { x = 0,    y = 568, w = 800,  h = 32 },  -- ground segment 1
    { x = 900,  y = 568, w = 600,  h = 32 },  -- ground segment 2
    { x = 1700, y = 568, w = 400,  h = 32 },  -- ground segment 3
    { x = 2300, y = 568, w = 900,  h = 32 },  -- ground segment 4
    { x = 350,  y = 420, w = 160,  h = 16 },  -- floating platform
    { x = 650,  y = 320, w = 160,  h = 16 },
    { x = 1050, y = 400, w = 160,  h = 16 },
    { x = 1350, y = 300, w = 160,  h = 16 },
    { x = 1600, y = 380, w = 160,  h = 16 },
    { x = 1850, y = 280, w = 160,  h = 16 },
    { x = 2100, y = 400, w = 160,  h = 16 },
    { x = 2500, y = 320, w = 160,  h = 16 },
    { x = 2800, y = 200, w = 160,  h = 16 },
}

local enemies = {
    { x = 500,  y = 540, w = 24, h = 24, dx = 80, speed = 60 },
    { x = 1000, y = 540, w = 24, h = 24, dx = 60, speed = 80 },
    { x = 1400, y = 540, w = 24, h = 24, dx = 70, speed = 50 },
    { x = 1900, y = 540, w = 24, h = 24, dx = 90, speed = 70 },
    { x = 2600, y = 540, w = 24, h = 24, dx = 60, speed = 65 },
}

local coins = {
    { x = 400, y = 390 }, { x = 700, y = 290 },
    { x = 1100, y = 370 }, { x = 1400, y = 270 },
    { x = 1650, y = 350 }, { x = 1900, y = 250 },
    { x = 2150, y = 370 }, { x = 2550, y = 290 },
    { x = 2850, y = 170 },
}

local goal = { x = 3100, y = 500, w = 40, h = 68 }

-- ── State ────────────────────────────────────────────────────────────
local State  = {}

-- ── Helpers ──────────────────────────────────────────────────────────

local function rectOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx
       and ay < by + bh and ay + ah > by
end

-- ── Lifecycle ────────────────────────────────────────────────────────

function State:enter()
    -- ── Player ──
    self.px = 100
    self.py = 500
    self.pw = 24
    self.ph = 32
    self.vx = 0
    self.vy = 0
    self.onGround = false
    self.facing  = 1      -- 1 = right, -1 = left
    self.coinCount = 0

    -- ── 1. Input system ──
    self.inp = input.new({
        bufferWindow = 0.05,
        defaultBindings = {
            left   = "left",
            right  = "right",
            jump   = "space",
        },
    })

    -- ── 2. Jump system ──
    self.jmp = jump.new({
        gravity       = GRAVITY,
        jumpVelocity  = -450,
        maxJumps      = 1,
        coyoteTime    = 0.08,
        bufferTime    = 0.08,
        variableHeight = true,
    })

    -- ── 3. Camera system ──
    self.camTarget = { x = self.px + self.pw/2, y = self.py + self.ph/2 }
    self.cam = camera.new({
        smoothing = 0.08,
        bounds = { 0, 0, LEVEL_W, LEVEL_H },
    })
    self.cam:follow(self.camTarget)

    -- ── 4. Health system ──
    self.hp = health.new({ maxHp = 100, iFrameDuration = 0.8 })
    self.hp:on("damaged", function() self._flashTimer = 0.15 end)
    self.hp:on("died",    function() self._gameOver = true end)

    -- ── 5. Timer system ──
    self.levelTimer = timer.new({ mode = "countdown", duration = 60 })
    self.levelTimer:on("expired", function() self._gameOver = true end)

    -- Enemy patrol state
    self._enemies = {}
    for i, e in ipairs(enemies) do
        self._enemies[i] = {
            x = e.x, y = e.y, w = e.w, h = e.h,
            originX = e.x, dx = e.dx, speed = e.speed,
            dir = 1,
        }
    end

    -- Coins collected tracker
    self._coins = {}
    for i, c in ipairs(coins) do
        self._coins[i] = { x = c.x, y = c.y, collected = false }
    end

    -- Game state
    self._gameOver = false
    self._win      = false
    self._flashTimer = 0
end

-- ── Collision: resolve against platforms ─────────────────────────────

function State:resolveCollision(dt)
    self.onGround = false

    -- Vertical (vy is in pixels/sec, multiply by dt)
    self.py = self.py + self.vy * dt

    for _, p in ipairs(platforms) do
        if rectOverlap(self.px, self.py, self.pw, self.ph, p.x, p.y, p.w, p.h) then
            if self.vy >= 0 then
                -- Landing
                self.py = p.y - self.ph
                self.vy = 0
                self.onGround = true
            else
                -- Head bump
                self.py = p.y + p.h
                self.vy = 0
            end
        end
    end

    -- Horizontal (vx is in pixels/sec, multiply by dt)
    self.px = self.px + self.vx * dt

    for _, p in ipairs(platforms) do
        if rectOverlap(self.px, self.py, self.pw, self.ph, p.x, p.y, p.w, p.h) then
            if self.vx > 0 then
                self.px = p.x - self.pw
            elseif self.vx < 0 then
                self.px = p.x + p.w
            end
            self.vx = 0
        end
    end

    -- Level bounds
    self.px = math.max(0, math.min(self.px, LEVEL_W - self.pw))
    if self.py > LEVEL_H then
        self:_die()
    end
end

-- ── Update ───────────────────────────────────────────────────────────

function State:update(dt)
    if self._gameOver or self._win then return end

    -- ── 1. Tick timer ──
    self.levelTimer:update(dt)

    -- ── 2. Input ──
    local moveDir = 0
    local leftDown  = self.inp:isPressed("left")
    local rightDown = self.inp:isPressed("right")
    if leftDown  then moveDir = moveDir - 1 end
    if rightDown then moveDir = moveDir + 1 end
    self.vx = moveDir * MOVE_SPEED
    if moveDir ~= 0 then self.facing = moveDir end

    -- Jump: only on the frame the key is FIRST pressed (not held)
    local jumpDown = self.inp:isPressed("jump")
    if jumpDown and not self._jumpWasDown then
        self.jmp:jump()
    end
    self._jumpWasDown = jumpDown

    -- ── 3. Jump system ──
    self.jmp.grounded = self.onGround
    self.jmp:update(dt)
    self.vy = self.jmp:getVelocity()

    -- ── 4. Apply gravity if not handled by jump ──
    -- Jump system already applies gravity internally via :update()
    -- when not grounded. So vy is already set.

    -- ── 5. Resolve collisions ──
    self:resolveCollision(dt)

    -- Sync jump system's grounded after collision resolution
    self.jmp.grounded = self.onGround

    -- ── 6. Health system ──
    self.hp:update(dt)

    -- Enemy collision → damage
    for _, e in ipairs(self._enemies) do
        if rectOverlap(self.px, self.py, self.pw, self.ph, e.x, e.y, e.w, e.h) then
            self.hp:takeDamage(20, "enemy")
        end
    end

    -- ── 7. Update camera ──
    self.camTarget.x = self.px + self.pw/2
    self.camTarget.y = self.py + self.ph/2
    self.cam:update(dt)

    -- ── 8. Move enemies ──
    for _, e in ipairs(self._enemies) do
        e.x = e.x + e.speed * e.dir * dt
        if math.abs(e.x - e.originX) >= e.dx then
            e.dir = e.dir * -1
        end
    end

    -- ── 9. Collect coins ──
    for _, c in ipairs(self._coins) do
        if not c.collected then
            if math.abs(self.px + self.pw/2 - c.x) < 20
            and math.abs(self.py + self.ph/2 - c.y) < 20 then
                c.collected = true
                self.coinCount = self.coinCount + 1
            end
        end
    end

    -- ── 10. Goal check ──
    if rectOverlap(self.px, self.py, self.pw, self.ph,
                   goal.x, goal.y, goal.w, goal.h) then
        self._win = true
    end

    -- Flash timer
    if self._flashTimer > 0 then
        self._flashTimer = math.max(0, self._flashTimer - dt)
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────

function State:draw()
    love.graphics.clear(COLORS.bg)

    self.cam:attach()

    -- ── Draw grid background ──
    love.graphics.setColor(0.06, 0.06, 0.10)
    for x = 0, LEVEL_W, 48 do
        love.graphics.line(x, 0, x, LEVEL_H)
    end
    for y = 0, LEVEL_H, 48 do
        love.graphics.line(0, y, LEVEL_W, y)
    end

    -- ── Draw platforms ──
    love.graphics.setColor(COLORS.ground)
    for _, p in ipairs(platforms) do
        love.graphics.rectangle("fill", p.x, p.y, p.w, p.h)
        -- Top edge highlight
        love.graphics.setColor(0.35, 0.35, 0.55)
        love.graphics.rectangle("fill", p.x, p.y, p.w, 2)
        love.graphics.setColor(COLORS.ground)
    end

    -- ── Draw coins ──
    for _, c in ipairs(self._coins) do
        if not c.collected then
            local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 3 + c.x)
            love.graphics.setColor(COLORS.coin[1], COLORS.coin[2], COLORS.coin[3], pulse)
            love.graphics.circle("fill", c.x, c.y, 8)
            love.graphics.setColor(1, 1, 1, 0.4)
            love.graphics.circle("line", c.x, c.y, 8)
        end
    end

    -- ── Draw enemies ──
    for _, e in ipairs(self._enemies) do
        love.graphics.setColor(COLORS.enemy)
        love.graphics.rectangle("fill", e.x, e.y, e.w, e.h)
        -- Eyes
        local eyeDir = e.dir
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", e.x + (eyeDir > 0 and 16 or 8), e.y + 8, 3)
        love.graphics.circle("fill", e.x + (eyeDir > 0 and 16 or 8), e.y + 16, 3)
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", e.x + (eyeDir > 0 and 17 or 9), e.y + 8, 1.5)
        love.graphics.circle("fill", e.x + (eyeDir > 0 and 17 or 9), e.y + 16, 1.5)
    end

    -- ── Draw goal ──
    love.graphics.setColor(COLORS.goal)
    love.graphics.rectangle("fill", goal.x, goal.y, goal.w, goal.h)
    -- Goal flag
    love.graphics.setColor(0.227, 0.929, 0.486, 0.6)
    love.graphics.polygon("fill",
        goal.x + goal.w, goal.y,
        goal.x + goal.w + 30, goal.y + 20,
        goal.x + goal.w, goal.y + 40)

    -- ── Draw player ──
    -- Flash red when damaged
    if self._flashTimer > 0 and math.floor(self._flashTimer * 20) % 2 == 0 then
        love.graphics.setColor(1, 1, 1)
    elseif self.hp:isInvincible() and math.floor(love.timer.getTime() * 10) % 2 == 0 then
        love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
    else
        love.graphics.setColor(COLORS.player)
    end
    love.graphics.rectangle("fill", self.px, self.py, self.pw, self.ph)
    -- Eyes
    love.graphics.setColor(1, 1, 1)
    local ex = self.px + (self.facing > 0 and 14 or 6)
    love.graphics.circle("fill", ex, self.py + 10, 3)
    love.graphics.circle("fill", ex, self.py + 20, 3)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", ex + self.facing, self.py + 10, 1.5)
    love.graphics.circle("fill", ex + self.facing, self.py + 20, 1.5)

    self.cam:detach()

    -- ── HUD (screen space) ──
    self:drawHUD()
end

function State:drawHUD()
    -- HP bar
    local barX, barY, barW, barH = 10, 10, 200, 18
    local hpRatio = self.hp:getCurrentHp() / self.hp:getMaxHp()

    love.graphics.setColor(COLORS.hpBg)
    love.graphics.rectangle("fill", barX, barY, barW, barH)
    love.graphics.setColor(
        COLORS.hp[1] * (1 - hpRatio) + 0.227 * hpRatio,
        COLORS.hp[2] * hpRatio,
        COLORS.hp[3] * hpRatio,
        1
    )
    love.graphics.rectangle("fill", barX, barY, barW * hpRatio, barH)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("line", barX, barY, barW, barH)

    -- HP text
    love.graphics.setColor(1, 1, 1)
    local hpText = math.ceil(self.hp:getCurrentHp()) .. " / " .. self.hp:getMaxHp()
    love.graphics.printf(hpText, barX + 5, barY + 2, barW - 10, "left")

    -- Timer
    love.graphics.setColor(1, 1, 1)
    local timeLeft = math.ceil(self.levelTimer:getRemaining() or 0)
    local timerColor = timeLeft <= 10 and {1, 0.2, 0.2} or {1, 1, 1}
    love.graphics.setColor(timerColor)
    love.graphics.printf("Time: " .. timeLeft .. "s", 10, 36, 200, "left")

    -- Coins
    love.graphics.setColor(COLORS.coin)
    love.graphics.printf("Coins: " .. self.coinCount .. " / " .. #coins, 10, 56, 200, "left")

    -- Controls hint
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.printf("Arrow keys + Space  |  ESC to pause", 0, H - 20, W, "center")

    -- Death screen
    if self._gameOver then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, W, H)
        love.graphics.setColor(1, 0.2, 0.2)
        local font = love.graphics.newFont(48)
        love.graphics.setFont(font)
        love.graphics.printf("GAME OVER", 0, H/2 - 60, W, "center")
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.printf("Press R to restart", 0, H/2 + 20, W, "center")
    end

    -- Win screen
    if self._win then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, W, H)
        love.graphics.setColor(COLORS.goal)
        local font = love.graphics.newFont(48)
        love.graphics.setFont(font)
        love.graphics.printf("YOU WIN!", 0, H/2 - 60, W, "center")
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.setColor(1, 1, 1, 0.6)
        local remaining = math.ceil(self.levelTimer:getRemaining() or 0)
        love.graphics.printf(
            "Time left: " .. remaining .. "s  |  Coins: " .. self.coinCount,
            0, H/2 + 10, W, "center"
        )
        love.graphics.printf("Press R to play again", 0, H/2 + 40, W, "center")
    end
end

-- ── Input ────────────────────────────────────────────────────────────

function State:keyreleased(key)
    if key == "escape" then
        Gamestate.push(Pause)
    end

    -- Jump release for variable height
    if key == "space" then
        self.jmp:release()
    end

    -- Restart on game over / win
    if (self._gameOver or self._win) and key == "r" then
        Gamestate.switch(require("src.states.game"))
    end
end

-- ── Internal ─────────────────────────────────────────────────────────

function State:_die()
    self._gameOver = true
end

return State
