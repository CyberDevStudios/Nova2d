-- Nova2D — splash screen state
-- Galaxy/nebula theme with white vector logo, particle stars, and smooth animations.
-- src/states/splash.lua

local hotreload = require("src.hotreload")
local Gamestate = require "hump.gamestate"

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local W, H = 800, 500
local CENTER_X, CENTER_Y = 400, 240
local STAR_COUNT = 120
local SPLASH_DURATION = 3.0
local COLORS = {
    purple = {0.486, 0.227, 0.929},    -- #7c3aed
    indigo = {0.388, 0.400, 0.945},    -- #6366f1
    blue   = {0.231, 0.510, 0.965},    -- #3b82f6
}

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local logo = nil
local elapsed = 0
local timer = SPLASH_DURATION
local logoScale = 0.85
local infoAlpha = 0
local stars = {}

-- Cached fonts
local fontInfo
local fontTagline
local fontSkip

-- Nebula structs (set up in enter)
local nebulaLayers = {}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function lerp(a, b, t) return a + (b - a) * t end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function spawnStars(count)
    for i = 1, count do
        stars[i] = {
            x = math.random(0, W),
            y = math.random(0, H),
            r = math.random() < 0.15 and 1.5 or (0.5 + math.random() * 0.8),
            speed = 3 + math.random() * 12,
            phase = math.random() * math.pi * 2,
            drift = (math.random() - 0.5) * 4,
        }
    end
end

local function buildNebula()
    -- Pre-compute nebula cloud layers: big translucent circles
    -- with different colours, positions, and sizes.
    local presets = {
        { cx = 0.25, cy = 0.30, r = 220, c = COLORS.purple, a0 = 0.06 },
        { cx = 0.70, cy = 0.25, r = 180, c = COLORS.indigo, a0 = 0.05 },
        { cx = 0.50, cy = 0.55, r = 200, c = COLORS.blue,   a0 = 0.04 },
        { cx = 0.80, cy = 0.60, r = 140, c = COLORS.purple, a0 = 0.03 },
        { cx = 0.15, cy = 0.50, r = 160, c = COLORS.blue,   a0 = 0.03 },
    }
    for i, p in ipairs(presets) do
        nebulaLayers[i] = {
            x = p.cx * W, y = p.cy * H, r = p.r,
            cr = p.c[1], cg = p.c[2], cb = p.c[3],
            alpha = p.a0,
        }
    end
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

function State:enter()
    hotreload.patch()

    -- Load white vector logo
    local ok, img = pcall(love.graphics.newImage, "assets/images/logo.png")
    logo = ok and img or nil

    -- Reset
    timer = SPLASH_DURATION
    elapsed = 0
    logoScale = 0.80
    infoAlpha = 0
    stars = {}
    spawnStars(STAR_COUNT)

    if #nebulaLayers == 0 then buildNebula() end

    -- Fonts (one-time)
    fontInfo   = love.graphics.newFont(14)
    fontTagline = love.graphics.newFont(11)
    fontSkip   = love.graphics.newFont(10)
end

function State:update(dt)
    elapsed = elapsed + dt
    timer = timer - dt

    -- Logo scale: smooth ease-out from 0.80 → 1.0 in 1s
    if elapsed < 1.0 then
        local t = elapsed / 1.0
        logoScale = 0.80 + 0.20 * (1 - (1 - t) * (1 - t) * (1 - t))
    else
        logoScale = 1.0
    end

    -- Info alpha: fade in after 0.8s
    if elapsed > 0.8 then
        infoAlpha = clamp((elapsed - 0.8) / 0.6, 0, 1)
    end

    -- Stars
    for _, s in ipairs(stars) do
        s.y = s.y - s.speed * dt
        s.x = s.x + s.drift * dt
        if s.y < -5 then
            s.y = H + 5
            s.x = math.random(0, W)
        end
        if s.x < -5 then s.x = W + 5 end
        if s.x > W + 5 then s.x = -5 end
    end

    if timer <= 0 then
        Gamestate.switch(require("src.states.menu"))
    end
end

function State:keypressed()
    Gamestate.switch(require("src.states.menu"))
end
State.mousepressed = State.keypressed

-- ---------------------------------------------------------------------------
-- Draw
-- ---------------------------------------------------------------------------

function State:draw()
    -- 1. Deep space background (#0a0a0f)
    love.graphics.clear(0.039, 0.039, 0.059)

    -- 2. Nebula clouds (soft colour washes)
    for _, n in ipairs(nebulaLayers) do
        love.graphics.setColor(n.cr, n.cg, n.cb, n.alpha)
        love.graphics.circle("fill", n.x, n.y, n.r)
    end

    -- 3. Glow aura behind logo
    --    Multi-layered circles in galaxy colours fading outward.
    love.graphics.setColor(0.486, 0.227, 0.929, 0.035)
    love.graphics.circle("fill", CENTER_X, CENTER_Y, 180 * logoScale)
    love.graphics.setColor(0.388, 0.400, 0.945, 0.030)
    love.graphics.circle("fill", CENTER_X, CENTER_Y, 140 * logoScale)
    love.graphics.setColor(0.231, 0.510, 0.965, 0.025)
    love.graphics.circle("fill", CENTER_X, CENTER_Y, 100 * logoScale)
    love.graphics.setColor(1, 1, 1, 0.05)
    love.graphics.circle("fill", CENTER_X, CENTER_Y, 60 * logoScale)

    -- 4. Star field
    for _, s in ipairs(stars) do
        local twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(elapsed * 2.0 + s.phase))
        local a = twinkle * clamp(s.y / H * 2, 0, 1)
        love.graphics.setColor(1, 1, 1, a * 0.45)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end

    -- 5. White vector logo (centred, scaled)
    if logo then
        love.graphics.setColor(1, 1, 1)
        local sx = math.min(280 / logo:getWidth(), 220 / logo:getHeight()) * logoScale
        love.graphics.draw(logo, CENTER_X, CENTER_Y - 15, 0, sx, sx,
                           logo:getWidth() / 2, logo:getHeight() / 2)
    end

    -- 6. Info overlay (fade in)
    local ia = infoAlpha

    -- Version
    love.graphics.setFont(fontInfo)
    love.graphics.setColor(1, 1, 1, 0.20 * ia)
    love.graphics.printf("v0.4", 0, CENTER_Y + 62, W, "center")

    -- Tagline
    love.graphics.setFont(fontTagline)
    love.graphics.setColor(0.486, 0.227, 0.929, 0.20 * ia)
    love.graphics.printf("A Love2D Framework", 0, CENTER_Y + 80, W, "center")

    -- 7. Skip hint (bottom, pulsing)
    love.graphics.setFont(fontSkip)
    local pulse = 0.25 + math.abs(math.sin(elapsed * 1.5)) * 0.15
    love.graphics.setColor(1, 1, 1, pulse * ia)
    love.graphics.printf("Press any key to skip", 0, H - 28, W, "center")

    love.graphics.setColor(1, 1, 1)
end

return State
