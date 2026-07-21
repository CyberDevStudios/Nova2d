-- Nova2D — new project workspace
-- src/states/game.lua
-- This is the blank canvas where users build their game.
-- No game logic here — just a clean starting point.

local Gamestate = require "hump.gamestate"
local Pause  = require("src.states.pause")
local VERSION = require("src.version")

local State = {}
local fontTitle, fontInfo, fontSmall

function State:enter()
    fontTitle = love.graphics.newFont(28)
    fontInfo  = love.graphics.newFont(16)
    fontSmall = love.graphics.newFont(13)
end

function State:update(dt) end

function State:draw()
    love.graphics.clear(0.039, 0.039, 0.059)

    local w, h = love.graphics.getDimensions()
    local cx = w / 2

    -- Title
    love.graphics.setFont(fontTitle)
    love.graphics.setColor(0.486, 0.227, 0.929, 0.6)
    love.graphics.printf("Nova2D Framework", 0, h * 0.22, w, "center")

    -- Version
    love.graphics.setFont(fontInfo)
    love.graphics.setColor(1, 1, 1, 0.25)
    love.graphics.printf("v" .. VERSION, 0, h * 0.22 + 36, w, "center")

    -- Divider
    love.graphics.setColor(0.486, 0.227, 0.929, 0.15)
    love.graphics.line(cx - 80, h * 0.22 + 62, cx + 80, h * 0.22 + 62)

    -- Message
    love.graphics.setFont(fontInfo)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.printf("Your game starts here — it's a blank canvas.",
                         0, h * 0.22 + 80, w, "center")

    -- Available systems reference
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.printf("Available systems: camera · input · timer · jump · health",
                         0, h * 0.22 + 116, w, "center")
    love.graphics.printf("Documentation: nova2d.dev",
                         0, h - 32, w, "center")

    love.graphics.setColor(1, 1, 1)
end

function State:keyreleased(key)
    if key == "escape" then
        Gamestate.push(Pause)
    end
end

return State
