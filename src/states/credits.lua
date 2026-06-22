-- Nova2D — credits screen state
-- src/states/credits.lua

local Gamestate = require "hump.gamestate"

local credits = {
    { lib = "hump.gamestate", author = "vrld",     purpose = "State machine / scene management" },
    { lib = "bump.lua",       author = "kikito",   purpose = "AABB collision detection" },
    { lib = "anim8",          author = "kikito",   purpose = "Sprite animation" },
    { lib = "lurker",         author = "rxi",      purpose = "Live reload on file save" },
    { lib = "lovebird",       author = "rxi",      purpose = "Remote debug panel" },
}

local State = {}

function State:enter() end

function State:update(dt) end

function State:draw()
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)

    -- Header
    local headerFont = love.graphics.setNewFont(36)
    love.graphics.printf("Nova2D v0.1", 0, 60, 800, "center")
    love.graphics.setFont(headerFont)

    -- Subtitle
    local subFont = love.graphics.setNewFont(18)
    love.graphics.printf("Framework libraries and credits", 0, 110, 800, "center")
    love.graphics.setFont(subFont)

    -- Library list
    local libFont = love.graphics.setNewFont(20)
    local y = 180
    for _, entry in ipairs(credits) do
        love.graphics.printf(entry.lib .. " by " .. entry.author, 0, y, 800, "center")
        y = y + 28
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.printf(entry.purpose, 0, y, 800, "center")
        love.graphics.setColor(1, 1, 1)
        y = y + 36
    end
    love.graphics.setFont(libFont)

    -- Return hint
    local hintFont = love.graphics.setNewFont(16)
    love.graphics.printf("Press ESC / Enter / Backspace or click to return", 0, 500, 800, "center")
    love.graphics.setFont(hintFont)
end

function State:keyreleased(key)
    if key == "escape" or key == "return" or key == "backspace" then
        Gamestate.switch(require("src.states.menu"))
    end
end

function State:mousepressed(x, y, button)
    Gamestate.switch(require("src.states.menu"))
end

return State
