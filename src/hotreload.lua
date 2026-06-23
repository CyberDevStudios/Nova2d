-- Nova2D — Hot reload bootstrapper
-- Initializes lurker for live code reloading.
-- Called once from splash.lua. Does NOT modify main.lua.

-- Extend require path to resolve libs/ (safety net — conf.lua already does this)
love.filesystem.setRequirePath(
    "?.lua;?/init.lua;libs/?.lua;libs/?/?.lua;libs/?/init.lua"
)

local lurker = require("lurker")
lurker.path = "src"
lurker.interval = 0.5

lurker.postswap = function(name)
    print("[HOTRELOAD] " .. name .. " reloaded")
end

-- Called from splash.lua's enter() AFTER Gamestate.registerEvents()
-- has set up love.update. This is the correct timing.
function patch_update()
    local original_update = love.update
    love.update = function(dt)
        lurker.update()
        original_update(dt)
    end
end

return { patch = patch_update }
