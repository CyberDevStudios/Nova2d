-- Nova2D — Entity Manager
-- src/systems/entitymanager.lua
-- Central registry for game entities. Drives the enter/update/draw/leave
-- lifecycle, keeps update and draw order per layer (z-order), supports
-- tags and queries, deferred removal, and simple system composition.
--
-- Entities are plain tables built with the metatable constructor pattern
-- (see docs/core-concepts/entities.md). The manager never modifies the
-- entity modules themselves.

local entitymanager = {}
entitymanager.__index = entitymanager

local DEFAULTS = {
    layers = { "default" },
}

--- Create a new entity manager.
-- @param config  Optional config table
--   layers = { "background", "actors", "effects" }
--     Update/draw order, back to front. The first layer is the default.
-- @return entitymanager instance
function entitymanager.new(config)
    config = config or {}
    local self = setmetatable({}, entitymanager)

    self.layers = config.layers or DEFAULTS.layers

    -- Per-layer entity lists, kept in insertion order
    self._byLayer = {}
    for _, name in ipairs(self.layers) do
        self._byLayer[name] = {}
    end

    self._present   = {}   -- entity -> true
    self._pending   = {}   -- entity -> true (flushed at end of update)
    self._callbacks = {}

    return self
end

-- ── Internals ───────────────────────────────────────────────────────

function entitymanager:_fire(event, ...)
    local cbs = self._callbacks[event]
    if cbs then
        for _, cb in ipairs(cbs) do
            cb(...)
        end
    end
end

--- Iterate every registered entity in layer order.
function entitymanager:_each(fn)
    for _, name in ipairs(self.layers) do
        local list = self._byLayer[name]
        for i = 1, #list do
            fn(list[i])
        end
    end
end

function entitymanager:_moveToLayer(entity, layer)
    local from = self._byLayer[entity.layer]
    if from then
        for i = #from, 1, -1 do
            if from[i] == entity then
                table.remove(from, i)
                break
            end
        end
    end
    entity.layer = layer
    table.insert(self._byLayer[layer], entity)
end

--- Update the systems attached to an entity, in attachment order.
-- Runs before the entity's own update(dt) so the entity reads fresh
-- system state (e.g. jump velocity, i-frame timer) in the same frame.
function entitymanager:_updateSystems(entity, dt)
    local order = entity._systemOrder
    if not order then return end
    for i = 1, #order do
        local system = entity[order[i]]
        if system and system.update then
            system:update(dt)
        end
    end
end

--- Apply every scheduled removal. Called at the end of update(dt) and
-- again at the start of the next one, so removals requested from
-- anywhere (inside entity updates, state code, callbacks) never
-- corrupt an iteration in progress.
function entitymanager:_flushRemovals()
    if not next(self._pending) then return end

    local removed = {}
    for _, name in ipairs(self.layers) do
        local list = self._byLayer[name]
        local keep = {}
        for i = 1, #list do
            local e = list[i]
            if self._pending[e] then
                removed[#removed + 1] = e
            else
                keep[#keep + 1] = e
            end
        end
        self._byLayer[name] = keep
    end

    for _, e in ipairs(removed) do
        self._pending[e] = nil
        self._present[e] = nil
        if e.leave then
            e:leave()
        end
        self:_fire("removed", e)
    end
end

-- ── Registry ────────────────────────────────────────────────────────

--- Register an entity and call its enter() lifecycle hook.
-- @param entity  Entity instance (metatable constructor pattern)
-- @param layer   Optional layer name; defaults to entity.layer or the
--                first configured layer
-- @return entity
function entitymanager:add(entity, layer)
    layer = layer or entity.layer or self.layers[1]

    if not self._byLayer[layer] then
        error("entitymanager:add: unknown layer '" .. tostring(layer) .. "'", 2)
    end

    -- A removal scheduled this frame is cancelled by re-adding
    if self._pending[entity] then
        self._pending[entity] = nil
        if entity.layer ~= layer then
            self:_moveToLayer(entity, layer)
        end
        return entity
    end

    if self._present[entity] then
        error("entitymanager:add: entity is already registered", 2)
    end

    entity.layer = layer
    if entity.enter then
        entity:enter(self)
    end

    table.insert(self._byLayer[layer], entity)
    self._present[entity] = true
    self:_fire("added", entity)

    return entity
end

--- Schedule an entity for removal.
-- The entity keeps its place until the end of the current update(dt)
-- (or the next one when called between frames), so removing entities
-- from inside an update callback is always safe. leave() and the
-- "removed" event fire at that point.
-- @param entity  Entity previously added
-- @return boolean  true when the entity was registered
function entitymanager:remove(entity)
    if not self._present[entity] then
        return false
    end
    self._pending[entity] = true
    return true
end

--- Remove every entity immediately (leave() + "removed" for each).
-- @return self  (for chaining)
function entitymanager:clear()
    for _, name in ipairs(self.layers) do
        local list = self._byLayer[name]
        -- Swap the list first so callbacks can safely add new entities
        self._byLayer[name] = {}
        for i = 1, #list do
            local e = list[i]
            self._present[e] = nil
            self._pending[e] = nil
            if e.leave then
                e:leave()
            end
            self:_fire("removed", e)
        end
    end
    return self
end

--- Reset to an empty registry (alias of clear()).
-- @return self  (for chaining)
function entitymanager:reset()
    return self:clear()
end

--- Move an entity to another layer (changes its z-order).
-- @param entity  Entity previously added
-- @param layer   Target layer name
-- @return entity
function entitymanager:setLayer(entity, layer)
    if not self._byLayer[layer] then
        error("entitymanager:setLayer: unknown layer '" .. tostring(layer) .. "'", 2)
    end
    if not self._present[entity] then
        entity.layer = layer
        return entity
    end
    if entity.layer ~= layer then
        self:_moveToLayer(entity, layer)
    end
    return entity
end

-- ── Composition ─────────────────────────────────────────────────────

--- Attach a system instance to an entity under a name.
-- The system becomes `entity[name]` (the demo uses player.jump,
-- player.health, player.animation) and is updated automatically before
-- the entity's own update(dt). Pick names that do not collide with the
-- entity's own fields or methods.
-- @param entity  Entity instance
-- @param name    Key to store the system under (e.g. "jump")
-- @param system  System instance (any table with an update(dt) method)
-- @return system
function entitymanager:attach(entity, name, system)
    if not entity._systemOrder then
        entity._systemOrder = {}
    end
    local known = false
    for i = 1, #entity._systemOrder do
        if entity._systemOrder[i] == name then
            known = true
            break
        end
    end
    if not known then
        entity._systemOrder[#entity._systemOrder + 1] = name
    end
    entity[name] = system
    return system
end

--- Detach a previously attached system.
-- @param entity  Entity instance
-- @param name    Key used in attach()
-- @return system|nil  The detached system
function entitymanager:detach(entity, name)
    local system = entity[name]
    if not system then
        return nil
    end
    entity[name] = nil
    if entity._systemOrder then
        for i = #entity._systemOrder, 1, -1 do
            if entity._systemOrder[i] == name then
                table.remove(entity._systemOrder, i)
            end
        end
    end
    return system
end

-- ── Queries ─────────────────────────────────────────────────────────

--- All entities carrying a tag in their `tags` array.
-- @param tag  Tag string
-- @return table  Array of entities (layer order)
function entitymanager:getByTag(tag)
    local found = {}
    self:_each(function(e)
        if e.tags then
            for _, t in ipairs(e.tags) do
                if t == tag then
                    found[#found + 1] = e
                    return
                end
            end
        end
    end)
    return found
end

--- All entities for which fn(entity) returns a truthy value.
-- @param fn  Filter function
-- @return table  Array of entities (layer order)
function entitymanager:query(fn)
    local found = {}
    self:_each(function(e)
        if fn(e) then
            found[#found + 1] = e
        end
    end)
    return found
end

-- ── Lifecycle ───────────────────────────────────────────────────────

--- Per-frame update.
-- Updates attached systems and entity:update(dt) for every entity, in
-- layer order. Entities added during the loop start updating next
-- frame; removals are applied when the loop finishes.
-- @param dt  Delta time in seconds
function entitymanager:update(dt)
    if dt <= 0 then
        self:_flushRemovals()
        return
    end

    -- Apply removals requested between frames
    self:_flushRemovals()

    for _, name in ipairs(self.layers) do
        local list = self._byLayer[name]
        -- Snapshot the count: entities added during this update start
        -- on the next frame.
        local n = #list
        for i = 1, n do
            local e = list[i]
            if not self._pending[e] then
                self:_updateSystems(e, dt)
                if e.update then
                    e:update(dt)
                end
            end
        end
    end

    -- Apply removals requested during this update
    self:_flushRemovals()
end

--- Draw every entity, in layer order (back to front).
function entitymanager:draw()
    for _, name in ipairs(self.layers) do
        local list = self._byLayer[name]
        for i = 1, #list do
            local e = list[i]
            if not self._pending[e] and e.draw then
                e:draw()
            end
        end
    end
end

-- ── Events ─────────────────────────────────────────────────────────

--- Register an event listener.
-- Supported events: added(entity), removed(entity)
-- @param event  Event name string
-- @param cb     Callback function
-- @return function  The callback (for use with table.remove)
function entitymanager:on(event, cb)
    if not self._callbacks[event] then
        self._callbacks[event] = {}
    end
    table.insert(self._callbacks[event], cb)
    return cb
end

return entitymanager
