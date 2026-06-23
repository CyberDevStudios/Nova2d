-- Nova2D — window configuration
-- conf.lua

function love.conf(t)
    t.identity = "nova2d"
    t.window.title = "Nova2D"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.window.vsync = 1
    t.console = false
    t.modules.audio = false
    t.modules.physics = false
    t.modules.joystick = false
end

-- Extend require path to resolve libs/ dependencies
package.path = package.path .. ";libs/?.lua;libs/?/init.lua"
