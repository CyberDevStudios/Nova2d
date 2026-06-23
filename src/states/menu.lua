-- Nova2D — main menu state
-- Galaxy theme with logo, particle stars, and button-style menu items.
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

-- Button geometry
local BTN_W = 260
local BTN_H = 44
local BTN_R = 8

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
local fontLogo
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
    love.graphics.setColor(PURPLE[1], PURPLE[2], PURPLE[3], 0.04)
    love.graphics.circle("fill", 160, 180, 200)
    love.graphics.setColor(INDIGO[1], INDIGO[2], INDIGO[3], 0.03)
    love.graphics.circle("fill", 640, 120, 180)
    love.graphics.setColor(BLUE[1], BLUE[2], BLUE[3], 0.03)
    love.graphics.circle("fill", 400, 400, 200)
    love.graphics.setColor(PURPLE[1], PURPLE[2], PURPLE[3], 0.025)
    love.graphics.circle("fill", -50, 300, 160)
end

-- Draw a single button centered at (cx, cy)
local function drawButton(label, cx, cy, isSelected)
    local left = cx - BTN_W / 2
    local top  = cy - BTN_H / 2

    if isSelected then
        -- Filled background
        love.graphics.setColor(PURPLE[1], PURPLE[2], PURPLE[3], 0.12)
        love.graphics.rectangle("fill", left, top, BTN_W, BTN_H, BTN_R)
        -- Border glow
        love.graphics.setColor(PURPLE[1], PURPLE[2], PURPLE[3], 0.4)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", left, top, BTN_W, BTN_H, BTN_R)
        love.graphics.setLineWidth(1)

        -- Text: bright white
        love.graphics.setColor(1, 1, 1)
    else
        -- Subtle border only
        love.graphics.setColor(0.3, 0.3, 0.45, 0.25)
        love.graphics.rectangle("line", left, top, BTN_W, BTN_H, BTN_R)
        love.graphics.setColor(0.45, 0.45, 0.55, 0.55)
    end

    love.graphics.printf(label, 0, cy - 8, W, "center")
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

function State:enter()
    selected = 1
    elapsed = 0
    stars = {}
    spawnStars(60)

    local ok, img = pcall(love.graphics.newImage, "assets/images/logo.png")
    logo = ok and img or nil

    fontLogo    = love.graphics.newFont(30)
    fontItems   = love.graphics.newFont(22)
    fontVersion = love.graphics.newFont(11)
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
        local twinkle = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(elapsed * 1.8 + s.phase))
        local a = twinkle * math.min(s.y / H * 2, 1)
        love.graphics.setColor(1, 1, 1, a * 0.4)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end

    -- Logo
    if logo then
        love.graphics.setColor(1, 1, 1)
        local sx = math.min(90 / logo:getWidth(), 70 / logo:getHeight())
        love.graphics.draw(logo, CENTER_X, 70, 0, sx, sx,
                           logo:getWidth() / 2, logo:getHeight() / 2)
    end

    -- Title
    love.graphics.setFont(fontLogo)
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.printf("Nova2D", 0, 115, W, "center")

    -- Menu buttons
    local startY = 225
    local spacing = 64
    love.graphics.setFont(fontItems)

    for i, item in ipairs(menuItems) do
        drawButton(item.label, CENTER_X, startY + (i - 1) * spacing, i == selected)
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
    local startY = 225
    local spacing = 64
    for i in ipairs(menuItems) do
        local cy = startY + (i - 1) * spacing
        if math.abs(y - cy) < BTN_H / 2 + 4 then
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
