-- Nova2D — credits screen
-- Galaxy theme consistent with splash and menu.
-- src/states/credits.lua

local Gamestate = require "hump.gamestate"

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local W, H = 800, 500
local CENTER_X = 400
local PURPLE  = {0.486, 0.227, 0.929}
local INDIGO  = {0.388, 0.400, 0.945}
local BLUE    = {0.231, 0.510, 0.965}

-- ---------------------------------------------------------------------------
-- Data
-- ---------------------------------------------------------------------------
local credits = {
    { lib = "hump.gamestate", author = "vrld",   purpose = "State machine / scene management"   },
    { lib = "bump.lua",       author = "kikito", purpose = "AABB collision detection"           },
    { lib = "anim8",          author = "kikito", purpose = "Sprite animation"                    },
    { lib = "lurker",         author = "rxi",    purpose = "Live reload on file save"            },
    { lib = "lovebird",       author = "rxi",    purpose = "Remote debug panel"                  },
}

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local State = {}
local elapsed = 0
local logo = nil
local stars = {}
local fontLogo
local fontItem
local fontPurpose
local fontHint

local function ensureFont(font, size)
    if font then
        return font
    end
    return love.graphics.newFont(size)
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function spawnStars(count)
    for i = 1, count do
        stars[i] = {
            x = math.random(0, W),
            y = math.random(0, H),
            r = 0.5 + math.random() * 1.0,
            speed = 1.5 + math.random() * 6,
            phase = math.random() * math.pi * 2,
        }
    end
end

local function drawNebula()
    love.graphics.setColor(PURPLE[1], PURPLE[2], PURPLE[3], 0.03)
    love.graphics.circle("fill", 200, 120, 180)
    love.graphics.setColor(INDIGO[1], INDIGO[2], INDIGO[3], 0.025)
    love.graphics.circle("fill", 620, 380, 160)
    love.graphics.setColor(BLUE[1], BLUE[2], BLUE[3], 0.025)
    love.graphics.circle("fill", 100, 400, 140)
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

function State:enter()
    elapsed = 0
    stars = {}
    spawnStars(50)

    local ok, img = pcall(love.graphics.newImage, "assets/images/logo.png")
    logo = ok and img or nil

    fontLogo    = love.graphics.newFont(28)
    fontItem    = love.graphics.newFont(17)
    fontPurpose = love.graphics.newFont(13)
    fontHint    = love.graphics.newFont(12)
end

function State:update(dt)
    elapsed = elapsed + dt
    for _, s in ipairs(stars) do
        s.y = s.y - s.speed * dt
        if s.y < -5 then
            s.y = H + 5
            s.x = math.random(0, W)
        end
    end
end

function State:draw()
    love.graphics.clear(0.039, 0.039, 0.059)

    drawNebula()

    -- Stars
    for _, s in ipairs(stars) do
        local twinkle = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(elapsed * 1.5 + s.phase))
        local a = twinkle * math.min(s.y / H * 2, 1)
        love.graphics.setColor(1, 1, 1, a * 0.35)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end

    -- Logo (small)
    if logo then
        love.graphics.setColor(1, 1, 1)
        local sx = math.min(60 / logo:getWidth(), 48 / logo:getHeight())
        love.graphics.draw(logo, CENTER_X, 55, 0, sx, sx,
                           logo:getWidth() / 2, logo:getHeight() / 2)
    end

    -- Title
    love.graphics.setFont(ensureFont(fontLogo, 28))
    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.printf("Credits", 0, 90, W, "center")

    -- Accent line
    love.graphics.setColor(PURPLE[1], PURPLE[2], PURPLE[3], 0.3)
    love.graphics.line(340, 108, 460, 108)
    love.graphics.setColor(1, 1, 1)

    -- Library entries
    local y = 138
    local spacing = 48
    love.graphics.setFont(ensureFont(fontItem, 17))

    for i, entry in ipairs(credits) do
        -- Alternating subtle background
        if i % 2 == 0 then
            love.graphics.setColor(1, 1, 1, 0.02)
            love.graphics.rectangle("fill", 180, y - 6, 440, spacing - 4, 4)
        end

        -- Library name (white)
        love.graphics.setColor(1, 1, 1, 0.90)
        love.graphics.printf(entry.lib, 0, y, W, "center")

        -- Author (purple)
        love.graphics.setColor(PURPLE[1], PURPLE[2], PURPLE[3], 0.55)
        love.graphics.setFont(ensureFont(fontPurpose, 13))
        love.graphics.printf("by " .. entry.author, 0, y + 18, W, "center")

        -- Purpose (gray)
        love.graphics.setColor(0.45, 0.45, 0.55, 0.45)
        love.graphics.printf(entry.purpose, 0, y + 32, W, "center")

        love.graphics.setFont(ensureFont(fontItem, 17))
        y = y + spacing
    end

    -- Return hint
    love.graphics.setFont(ensureFont(fontHint, 12))
    love.graphics.setColor(0.3, 0.3, 0.5, 0.35)
    love.graphics.printf("Press ESC / Enter / Backspace or click to return", 0, H - 24, W, "center")

    love.graphics.setColor(1, 1, 1)
end

-- ---------------------------------------------------------------------------
-- Input
-- ---------------------------------------------------------------------------

function State:keyreleased(key)
    if key == "escape" or key == "return" or key == "backspace" or key == "space" then
        Gamestate.switch(require("src.states.menu"))
    end
end

function State:mousepressed(x, y, button)
    Gamestate.switch(require("src.states.menu"))
end

return State
