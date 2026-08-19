-- Nova2D — Collision System
-- src/systems/collision.lua
-- AABB collision wrapper over bump.lua (bundled dependency).
-- World-based spatial hashing with move/check/query, plus pure
-- geometry helpers for one-off overlap tests.

local bump = require("bump")

local collision = {}
collision.__index = collision

local DEFAULTS = {
    cellSize = 64,
}

-- ── Pure geometry helpers ───────────────────────────────────────────

--- Create an AABB box.
-- @param x  Left coordinate
-- @param y  Top coordinate
-- @param w  Width
-- @param h  Height
-- @return box  { x = x, y = y, w = w, h = h }
function collision.box(x, y, w, h)
    return { x = x, y = y, w = w, h = h }
end

--- Whether two boxes overlap (inclusive edges).
-- @param a  Box
-- @param b  Box
-- @return boolean
function collision.overlaps(a, b)
    return a.x < b.x + b.w and b.x < a.x + a.w
       and a.y < b.y + b.h and b.y < a.y + a.h
end

--- Whether a point is inside a box.
-- @param box  Box
-- @param px   Point x
-- @param py   Point y
-- @return boolean
function collision.contains(box, px, py)
    return px >= box.x and px <= box.x + box.w
       and py >= box.y and py <= box.y + box.h
end

-- ── World ───────────────────────────────────────────────────────────

--- Create a new collision world.
-- @param config  Optional config table (cellSize = 64 default)
-- @return world instance
function collision.new(config)
    config = config or {}
    local self = setmetatable({}, collision)

    for k, v in pairs(DEFAULTS) do
        self[k] = (config[k] ~= nil) and config[k] or v
    end

    self._bump = bump.newWorld(self.cellSize)
    self._callbacks = {}

    return self
end

--- Register an entity in the world.
-- Reads the collision box from entity.collider (x, y, w, h)
-- or falls back to entity.x, entity.y, entity.w, entity.h.
-- @param entity  Any table (used as the identity key)
-- @return entity
function collision:add(entity)
    local x, y, w, h = self:_readBox(entity)
    self._bump:add(entity, x, y, w, h)
    return entity
end

--- Remove an entity from the world.
-- @param entity  Entity previously added
function collision:remove(entity)
    self._bump:remove(entity)
end

--- Reposition an entity's collision box from its current fields.
-- Teleports without collision response and fires no events.
-- Use after directly moving entity.x/y.
-- @param entity  Entity previously added
function collision:update(entity)
    local x, y, w, h = self:_readBox(entity)
    self._bump:update(entity, x, y, w, h)
end

--- Move an entity toward a goal, resolving collisions.
-- Fires "collision" (entity, other, col) for every contact and
-- writes the resolved position back to the entity's fields.
-- @param entity  Entity previously added
-- @param goalX   Target x
-- @param goalY   Target y
-- @param filter  Optional bump filter function
-- @return actualX, actualY, collided
function collision:move(entity, goalX, goalY, filter)
    local actualX, actualY, cols, len = self._bump:move(entity, goalX, goalY, filter)

    local collided = false
    for i = 1, len do
        local col = cols[i]
        if col.other then
            collided = true
            self:_fire("collision", entity, col.other, col)
        end
    end

    self:_writeBack(entity, actualX, actualY)
    return actualX, actualY, collided
end

--- Check whether moving would collide, without moving or firing events.
-- @param entity  Entity previously added
-- @param goalX   Target x
-- @param goalY   Target y
-- @param filter  Optional bump filter function
-- @return boolean  collided
function collision:check(entity, goalX, goalY, filter)
    local _, _, _, len = self._bump:check(entity, goalX, goalY, filter)
    return len > 0
end

--- Query entities overlapping a rectangle.
-- @param x, y, w, h  Query region
-- @param filter      Optional bump filter function
-- @return table  List of entities
function collision:query(x, y, w, h, filter)
    return self._bump:queryRect(x, y, w, h, filter)
end

--- Query entities under a point.
-- @param x, y  Point
-- @return table  List of entities
function collision:queryPoint(x, y)
    return self._bump:queryPoint(x, y)
end

--- Remove every entity from the world.
-- @return self  (for chaining)
function collision:reset()
    local items = self._bump:getItems()
    for _, entity in ipairs(items) do
        self._bump:remove(entity)
    end
    return self
end

-- ── Events ─────────────────────────────────────────────────────────

--- Register an event listener.
-- Supported events: collision(entity, other, col)
-- @param event  Event name string
-- @param cb     Callback function
-- @return function  The callback (for use with table.remove)
function collision:on(event, cb)
    if not self._callbacks[event] then
        self._callbacks[event] = {}
    end
    table.insert(self._callbacks[event], cb)
    return cb
end

function collision:_fire(event, ...)
    local cbs = self._callbacks[event]
    if cbs then
        for _, cb in ipairs(cbs) do
            cb(...)
        end
    end
end

-- ── Internals ───────────────────────────────────────────────────────

function collision:_readBox(entity)
    local c = entity.collider or entity
    return c.x or 0, c.y or 0, c.w or 1, c.h or 1
end

function collision:_writeBack(entity, x, y)
    if entity.collider then
        entity.collider.x = x
        entity.collider.y = y
    else
        entity.x = x
        entity.y = y
    end
end

return collision