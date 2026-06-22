-- Nova2D — pause overlay state
-- src/states/pause.lua

local Gamestate = require "hump.gamestate"

local State = {}

function State:enter(previous)
    self.previous = previous
end

function State:update(dt)
    -- Propagate update to the underlying Game state so game logic continues
    if self.previous and self.previous.update then
        self.previous:update(dt)
    end
end

function State:draw()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 180 / 255)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    -- Pause text
    love.graphics.setColor(1, 1, 1)
    local pauseFont = love.graphics.setNewFont(48)
    love.graphics.printf("PAUSED", 0, 240, 800, "center")
    love.graphics.setFont(pauseFont)

    local hintFont = love.graphics.setNewFont(20)
    love.graphics.printf("Esc to resume", 0, 310, 800, "center")
    love.graphics.setFont(hintFont)
end

function State:keyreleased(key)
    if key == "escape" then
        Gamestate.pop()
    end
end

return State
