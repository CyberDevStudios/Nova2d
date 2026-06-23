-- Nova2D — splash screen state
-- src/states/splash.lua

local hotreload = require("src.hotreload")
local Gamestate = require "hump.gamestate"

local logo = nil
local timer = 3.0
local elapsed = 0
local particles = {}
local titleScale = 1.0
local versionAlpha = 0

-- Fonts (cached once in enter())
local fontTitle
local fontVersion
local fontSubtitle
local fontSkip

local function spawnParticles(count)
    for i = 1, count do
        table.insert(particles, {
            x = math.random(0, 800),
            y = math.random(500, 600),
            speed = 15 + math.random(35),
            r = 1 + math.random(2),
            alpha = 0,
        })
    end
end

local State = {}

function State:enter()
    hotreload.patch()

    logo = nil
    local ok, img = pcall(love.graphics.newImage, "assets/images/logo.png")
    logo = ok and img or nil

    timer = 3.0
    elapsed = 0
    titleScale = 0.7
    versionAlpha = 0
    particles = {}
    spawnParticles(50)

    -- One-time font creation
    fontTitle    = love.graphics.newFont(52)
    fontVersion  = love.graphics.newFont(15)
    fontSubtitle = love.graphics.newFont(12)
    fontSkip     = love.graphics.newFont(10)
end

function State:update(dt)
    elapsed = elapsed + dt
    timer = timer - dt

    -- Title scale: elastic ease-out (0.7 → 1.0 over 0.8s)
    if elapsed < 0.8 then
        local t = elapsed / 0.8
        -- Overshoot ease-out: goes to 1.05 then settles
        titleScale = 1.0 - math.cos(t * math.pi * 0.5) * 0.3
    else
        titleScale = 1.0
    end

    -- Version fade-in after 0.6s
    if elapsed > 0.6 then
        versionAlpha = math.min(1, (elapsed - 0.6) / 0.6)
    end

    -- Particles
    for _, p in ipairs(particles) do
        p.y = p.y - p.speed * dt
        p.alpha = math.max(0, math.min(1, p.y / 80 - 0.3))
        if p.y < -10 then
            p.y = 510
            p.x = math.random(0, 800)
            p.alpha = 0
        end
    end

    if timer <= 0 then
        Gamestate.switch(require("src.states.menu"))
    end
end

function State:keypressed()
    Gamestate.switch(require("src.states.menu"))
end

-- Keep mousepressed as well so skip works on click
State.mousepressed = State.keypressed

function State:draw()
    love.graphics.clear(0.07, 0.07, 0.14)

    local w, h = 800, 500

    -- Subtle radial vignette (manual gradient approximation)
    for r = 280, 60, -20 do
        local a = 0.15 * (1 - r / 280)
        love.graphics.setColor(0.12, 0.08, 0.25, a)
        love.graphics.circle("fill", 400, 240, r)
    end
    love.graphics.setColor(1, 1, 1, 1)

    -- Particles
    for _, p in ipairs(particles) do
        love.graphics.setColor(0.7, 0.6, 1.0, p.alpha * 0.4)
        love.graphics.circle("fill", p.x, p.y, p.r)
    end
    love.graphics.setColor(1, 1, 1, 1)

    if logo then
        -- Logo with scale animation
        local sx = math.min(360 / logo:getWidth(), 260 / logo:getHeight()) * titleScale
        love.graphics.draw(logo, 400, 230, 0, sx, sx, logo:getWidth() / 2, logo:getHeight() / 2)
    else
        -- Glow rings behind title
        love.graphics.setColor(0.35, 0.15, 0.70, 0.08)
        love.graphics.circle("fill", 400, 215, 130 * titleScale)
        love.graphics.setColor(0.25, 0.10, 0.50, 0.12)
        love.graphics.circle("fill", 400, 215, 90 * titleScale)

        -- Title with scale transform
        love.graphics.push()
        love.graphics.translate(400, 194)
        love.graphics.scale(titleScale)
        love.graphics.translate(-400, -194)

        -- Shadow layers
        love.graphics.setFont(fontTitle)
        for i = 1, 4 do
            local a = 0.15 - i * 0.03
            if a > 0 then
                love.graphics.setColor(0, 0, 0, a)
                love.graphics.printf("Nova2D", 2 + i * 1.5, 196 + i * 1.5, w, "center")
            end
        end

        -- Glow text
        love.graphics.setColor(0.4, 0.2, 0.8, 0.25)
        love.graphics.printf("Nova2D", 0, 196, w, "center")

        -- Main text
        love.graphics.setColor(0.92, 0.90, 1.0, 1)
        love.graphics.printf("Nova2D", 0, 194, w, "center")

        love.graphics.pop()

        -- Accent line
        love.graphics.setColor(0.40, 0.25, 0.75, 0.5)
        love.graphics.line(280, 226, 520, 226)

        -- Version
        love.graphics.setFont(fontVersion)
        love.graphics.setColor(0.65, 0.50, 1.0, 0.25 + versionAlpha * 0.55)
        love.graphics.printf("v0.4", 0, 232, w, "center")
    end

    -- Tagline (always show, subtle)
    love.graphics.setFont(fontSubtitle)
    love.graphics.setColor(0.35, 0.30, 0.50, 0.35 + versionAlpha * 0.25)
    love.graphics.printf("A Love2D Framework", 0, 270, w, "center")

    -- Skip hint
    love.graphics.setFont(fontSkip)
    local pulse = 0.3 + math.abs(math.sin(elapsed * 1.5)) * 0.2
    love.graphics.setColor(0.30, 0.30, 0.50, pulse)
    love.graphics.printf("Press any key to skip", 0, h - 30, w, "center")

    love.graphics.setColor(1, 1, 1, 1)
end

return State
