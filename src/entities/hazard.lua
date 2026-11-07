-- Nova2D — Hazard entity (mini-platformer demo)
-- src/entities/hazard.lua
-- Static spike that damages the player on contact. It is solid, so the
-- collision world resolves the contact and fires the "collision" event;
-- the game state listens and applies the damage (see src/states/game.lua).

local Hazard = {}
Hazard.__index = Hazard

--- Create a spike strip.
-- @param x, y  Position (top-left of the hitbox)
-- @param w     Width in pixels (each spike is 8px wide)
-- @param damage  Damage dealt on contact
-- @return Hazard instance
function Hazard.new(x, y, w, damage)
    local self = setmetatable({}, Hazard)
    self.x, self.y = x, y
    self.w = w or 32
    self.h = 12
    self.damage = damage or 10
    self.tags = { "hazard" }
    return self
end

function Hazard:draw()
    local count = math.max(1, math.floor(self.w / 8))
    local spikeW = self.w / count
    love.graphics.setColor(0.95, 0.45, 0.60)
    for i = 0, count - 1 do
        local x0 = self.x + i * spikeW
        love.graphics.polygon("fill",
            x0, self.y + self.h,
            x0 + spikeW / 2, self.y,
            x0 + spikeW, self.y + self.h)
    end
    love.graphics.setColor(1, 1, 1)
end

return Hazard
