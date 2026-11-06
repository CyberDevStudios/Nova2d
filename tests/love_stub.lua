-- Minimal Love2D stubs so the system specs run under plain Lua (busted)
-- without a window. Only the calls made by src/systems are stubbed.
--
-- Usage from a spec:
--   local stub = require("tests.love_stub")
--   stub.install()          -- sets the global `love`
--
-- `love.joystick` is intentionally absent (disabled module) — the input
-- system guards for it, which is part of what these tests verify.

local M = {}

M._time = 0
M._down = {}

M.timer = {
    getTime = function()
        return M._time
    end,
}

M.keyboard = {
    isDown = function(key)
        return M._down[key] == true
    end,
}

M.graphics = {
    getWidth = function() return 800 end,
    getHeight = function() return 600 end,
    newQuad = function(x, y, w, h, sw, sh)
        local quad = { x = x, y = y, w = w, h = h, sw = sw, sh = sh }
        function quad:getViewport()
            return self.x, self.y, self.w, self.h
        end
        return quad
    end,
    push = function() end,
    pop = function() end,
    translate = function() end,
    scale = function() end,
}

-- ── Test helpers ────────────────────────────────────────────────────

function M.reset()
    M._time = 0
    M._down = {}
end

function M.advance(dt)
    M._time = M._time + dt
end

function M.pressKey(key)
    M._down[key] = true
end

function M.releaseKey(key)
    M._down[key] = nil
end

function M.install()
    _G.love = M
end

return M
