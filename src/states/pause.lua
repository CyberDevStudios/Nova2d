-- Nova2D — pause overlay with menu quit option
-- src/states/pause.lua

local Gamestate = require "hump.gamestate"

local State = {}
local pauseItems = { "Resume", "Return to Menu" }
local selected = 1
local fontItems
local fontHint

function State:enter(previous)
    self.previous = previous
    selected = 1
    fontItems = love.graphics.newFont(22)
    fontHint  = love.graphics.newFont(14)
end

function State:update(dt)
    -- Keep game logic running underneath
    if self.previous and self.previous.update then
        self.previous:update(dt)
    end
end

function State:draw()
    -- Dark overlay
    love.graphics.setColor(0, 0, 0, 0.70)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    -- Pause title
    love.graphics.setColor(0.486, 0.227, 0.929, 0.5)
    local titleFont = love.graphics.setNewFont(42)
    love.graphics.printf("PAUSED", 0, 160, 800, "center")

    -- Options
    local startY = 260
    local spacing = 60
    love.graphics.setFont(fontItems)

    for i, label in ipairs(pauseItems) do
        local y = startY + (i - 1) * spacing
        local isSel = i == selected

        if isSel then
            -- Button background
            love.graphics.setColor(0.486, 0.227, 0.929, 0.15)
            love.graphics.rectangle("fill", 300, y - 16, 200, 36, 6)
            love.graphics.setColor(0.486, 0.227, 0.929, 0.4)
            love.graphics.rectangle("line", 300, y - 16, 200, 36, 6)
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.5, 0.5, 0.6, 0.5)
        end
        local fh = love.graphics.getFont():getHeight()
        love.graphics.printf(label, 0, y + fh * 0.35, 800, "center")
    end

    -- Hint
    love.graphics.setFont(fontHint)
    love.graphics.setColor(0.3, 0.3, 0.5, 0.4)
    love.graphics.printf("Navigate: ↑↓  Select: Enter", 0, 380, 800, "center")

    love.graphics.setColor(1, 1, 1)
end

function State:keyreleased(key)
    if key == "escape" then
        Gamestate.pop()
    elseif key == "up" or key == "w" then
        selected = selected - 1
        if selected < 1 then selected = #pauseItems end
    elseif key == "down" or key == "s" then
        selected = selected + 1
        if selected > #pauseItems then selected = 1 end
    elseif key == "return" or key == "space" then
        if pauseItems[selected] == "Resume" then
            Gamestate.pop()
        elseif pauseItems[selected] == "Return to Menu" then
            Gamestate.switch(require("src.states.menu"))
        end
    end
end

function State:mousepressed(x, y, button)
    if button ~= 1 then return end
    local startY = 260
    local spacing = 60
    for i in ipairs(pauseItems) do
        local cy = startY + (i - 1) * spacing
        if y >= cy - 18 and y <= cy + 18 then
            selected = i
            if pauseItems[i] == "Resume" then
                Gamestate.pop()
            elseif pauseItems[i] == "Return to Menu" then
                Gamestate.switch(require("src.states.menu"))
            end
            return
        end
    end
end

return State
