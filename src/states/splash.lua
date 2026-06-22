-- Nova2D — splash screen state
-- src/states/splash.lua

local Gamestate = require "hump.gamestate"

local logo = nil
local timer = 3.0

local State = {}

function State:enter()
    local ok, img = pcall(love.graphics.newImage, "assets/images/logo.png")
    logo = ok and img or nil
    timer = 3.0
end

function State:update(dt)
    timer = timer - dt
    if timer <= 0 then
        Gamestate.switch(require("src.states.menu"))
    end
end

function State:draw()
    love.graphics.clear()
    if logo then
        local sx = math.min(400 / logo:getWidth(), 300 / logo:getHeight())
        love.graphics.draw(logo, 400, 250, 0, sx, sx, logo:getWidth() / 2, logo:getHeight() / 2)
    else
        local font = love.graphics.setNewFont(36)
        love.graphics.printf("Nova2D", 0, 220, 800, "center")
        love.graphics.setFont(font)
    end
    local infoFont = love.graphics.setNewFont(14)
    love.graphics.printf("Nova2D v0.1", 0, 400, 800, "center")
    love.graphics.setFont(infoFont)
end

return State
