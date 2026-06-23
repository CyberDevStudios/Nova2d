-- Nova2D — main menu state
-- Galaxy theme with logo, particle stars, and animated menu items.
-- src/states/menu.lua

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
-- State
-- ---------------------------------------------------------------------------
local State = {}

local menuItems = {
    { label = "New Game" },
    { label = "Credits"  },
    { label = "Quit"     },
}
local selected = 1
local elapsed = 0
local logo = nil

local stars = {}
local fontTitle
local fontItems
local fontVersion

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function spawnStars(count)
    for i = 1, count do
        stars[i] = {
            x = math.random(0, W),
            y = math.random(0, H),
            r = 0.5 + math.random() * 1.2,
            speed = 2 + math.random() * 8,
            phase = math.random() * math.pi * 2,
        }
    end
end

local function drawNebula()
    -- Subtle colour washes behind the menu, same palette as splash.
    love.graphics.setColor(PURPLE[1], PURPLE[2], PURPLE[3], 0.04)
    love.graphics.circle("fill", 160, 180, 200)
    love.graphics.setColor(INDIGO[1], INDIGO[2], INDIGO[3], 0.03)
    love.graphics.circle("fill", 640, 120, 180)
    love.graphics.setColor(BLUE[1], BLUE[2], BLUE[3], 0.03)
    love.graphics.circle("fill", 400, 400, 200)
    love.graphics.setColor(PURPLE[1], PURPLE[2], PURPLE[3], 0.025)
    love.graphics.circle("fill", -50, 300, 160)
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

function State:enter()
    selected = 1
    elapsed = 0
    stars = {}
    spawnStars(60)

    -- Load logo (shared asset with splash)
    local ok, img = pcall(love.graphics.newImage, "assets/images/logo.png")
    logo = ok and img or nil

    -- Cached fonts
    fontTitle   = love.graphics.newFont(36)
    fontItems   = love.graphics.newFont(24)
    fontVersion = love.graphics.newFont(11)
end

function State:update(dt)
    elapsed = elapsed + dt

    -- Drift stars upward
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
        local twinkle = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(elapsed * 1.8 + s.phase))
        local a = twinkle * math.min(s.y / H * 2, 1)
        love.graphics.setColor(1, 1, 1, a * 0.4)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end

    -- Logo (smaller, at top)
    if logo then
        love.graphics.setColor(1, 1, 1)
        local sx = math.min(100 / logo:getWidth(), 80 / logo:getHeight())
        love.graphics.draw(logo, CENTER_X, 80, 0, sx, sx,
                           logo:getWidth() / 2, logo:getHeight() / 2)
    end

    -- Title
    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf("Nova2D", 0, 125, W, "center")

    -- Menu items
    local startY = 240
    local spacing = 60
    love.graphics.setFont(fontItems)

    for i, item in ipairs(menuItems) do
        local y = startY + (i - 1) * spacing
        local isSelected = i == selected

        if isSelected then
            -- Glow indicator (triangle)
            love.graphics.setColor(PURPLE[1], PURPLE[2], PURPLE[3], 0.5)
            love.graphics.polygon("fill",
                CENTER_X - 140, y - 2,
                CENTER_X - 128, y - 8,
                CENTER_X - 128, y + 4
            )

            -- Selected item: bright white with purple glow behind text
            love.graphics.setColor(PURPLE[1], PURPLE[2], PURPLE[3], 0.10)
            love.graphics.printf(item.label, 0, y - 1, W, "center")
            love.graphics.printf(item.label, 0, y + 1, W, "center")
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(item.label, 0, y, W, "center")
        else
            love.graphics.setColor(0.5, 0.5, 0.6, 0.6)
            love.graphics.printf(item.label, 0, y, W, "center")
        end
    end

    -- Version
    love.graphics.setFont(fontVersion)
    love.graphics.setColor(1, 1, 1, 0.12)
    love.graphics.printf("v0.4", 0, H - 22, W, "center")

    love.graphics.setColor(1, 1, 1)
end

-- ---------------------------------------------------------------------------
-- Input
-- ---------------------------------------------------------------------------

function State:keyreleased(key)
    if key == "up" or key == "w" then
        selected = selected - 1
        if selected < 1 then selected = #menuItems end
    elseif key == "down" or key == "s" then
        selected = selected + 1
        if selected > #menuItems then selected = 1 end
    elseif key == "return" or key == "space" then
        dispatchAction()
    end
end

function State:mousepressed(x, y, button)
    if button ~= 1 then return end
    local startY = 240
    local spacing = 60
    for i in ipairs(menuItems) do
        local cy = startY + (i - 1) * spacing
        if y >= cy - 20 and y <= cy + 20 then
            selected = i
            dispatchAction()
            return
        end
    end
end

-- ---------------------------------------------------------------------------
-- Dispatch
-- ---------------------------------------------------------------------------

function dispatchAction()
    local item = menuItems[selected]
    if item.label == "New Game" then
        Gamestate.switch(require("src.states.game"))
    elseif item.label == "Credits" then
        Gamestate.switch(require("src.states.credits"))
    elseif item.label == "Quit" then
        love.event.quit()
    end
end

return State
