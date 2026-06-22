-- Nova2D — main menu state
-- src/states/menu.lua

local Gamestate = require "hump.gamestate"

local menuItems = {
    { label = "New Game" },
    { label = "Credits" },
    { label = "Quit" },
}
local selected = 1

local State = {}

function State:enter()
    selected = 1
end

function State:update(dt) end

function State:draw()
    love.graphics.clear()
    -- Title
    love.graphics.setColor(1, 1, 1)
    local titleFont = love.graphics.setNewFont(48)
    love.graphics.printf("Nova2D", 0, 120, 800, "center")
    love.graphics.setFont(titleFont)

    -- Menu items
    local itemFont = love.graphics.setNewFont(28)
    local startY = 300
    local spacing = 60

    for i, item in ipairs(menuItems) do
        if i == selected then
            love.graphics.setColor(52 / 255, 152 / 255, 219 / 255)  -- highlight blue
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
        end
        love.graphics.printf(item.label, 0, startY + (i - 1) * spacing, 800, "center")
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(itemFont)
end

function State:keyreleased(key)
    if key == "up" then
        selected = selected - 1
        if selected < 1 then selected = #menuItems end
    elseif key == "down" then
        selected = selected + 1
        if selected > #menuItems then selected = 1 end
    elseif key == "return" or key == "space" then
        dispatchAction()
    end
end

function State:mousepressed(x, y, button)
    if button ~= 1 then return end
    local startY = 300
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
