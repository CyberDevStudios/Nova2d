-- Nova2D — game placeholder state
-- src/states/game.lua

local Gamestate = require "hump.gamestate"
local Pause = require("src.states.pause")

local State = {}

function State:enter() end

function State:update(dt) end

function State:draw()
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.setNewFont(24)
    love.graphics.printf("Game Screen — Your game goes here", 0, 280, 800, "center")
    love.graphics.setFont(font)
end

function State:keyreleased(key)
    if key == "escape" then
        Gamestate.push(Pause)
    end
end

return State
