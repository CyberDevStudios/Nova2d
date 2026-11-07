local EntityManager = require("src.systems.entitymanager")

-- Build a minimal fake entity that logs every lifecycle call.
local function ent(name, log)
    return {
        name = name,
        tags = {},
        enter = function(self, parent)
            log[#log + 1] = "enter:" .. self.name
            self.parent = parent
        end,
        leave = function(self)
            log[#log + 1] = "leave:" .. self.name
        end,
        update = function(self)
            log[#log + 1] = "update:" .. self.name
        end,
        draw = function(self)
            log[#log + 1] = "draw:" .. self.name
        end,
    }
end

-- Clear in place — the entities hold a reference to the same table.
local function clear(t)
    for i = #t, 1, -1 do
        t[i] = nil
    end
end

describe("Entity manager", function()

    it("add() calls enter(parent) and fires added", function()
        local em = EntityManager.new()
        local log = {}
        local e = ent("a", log)
        local added = {}
        em:on("added", function(entity) table.insert(added, entity) end)

        assert.equals(e, em:add(e))
        assert.are.same({ "enter:a" }, log)
        assert.equals(em, e.parent)
        assert.are.same({ e }, added)
    end)

    it("rejects duplicate adds and errors on unknown layers", function()
        local em = EntityManager.new()
        local e = ent("a", {})
        em:add(e)
        assert.has_error(function() em:add(e) end)
        assert.has_error(function() em:add(ent("b", {}), "nope") end)
    end)

    it("update() and draw() run in layer order", function()
        local em = EntityManager.new({ layers = { "back", "front" } })
        local log = {}
        local a = ent("back", log)
        local b = ent("front", log)
        em:add(a)
        em:add(b)

        clear(log)
        em:update(0.016)
        assert.are.same({ "update:back", "update:front" }, log)

        clear(log)
        em:draw()
        assert.are.same({ "draw:back", "draw:front" }, log)
    end)

    it("attached systems update before the entity's own update", function()
        local em = EntityManager.new()
        local log = {}
        local e = ent("e", log)
        local system = {
            update = function() log[#log + 1] = "sys:update" end,
        }
        em:add(e)
        em:attach(e, "jump", system)

        clear(log)
        em:update(0.016)
        assert.are.same({ "sys:update", "update:e" }, log)
    end)

    it("remove() is deferred: the entity finishes the current loop", function()
        local em = EntityManager.new()
        local log = {}

        local b
        local a = ent("a", log)
        a.update = function()
            log[#log + 1] = "update:a"
            em:remove(b)              -- schedule removal of b mid-iteration
        end
        b = ent("b", log)

        local removed = {}
        em:on("removed", function(entity) table.insert(removed, entity) end)

        em:add(a)
        em:add(b)
        clear(log)

        em:update(0.016)
        -- b must not update once removed, and removed/leave fire after the loop
        assert.are.same({ "update:a", "leave:b" }, log)
        assert.are.same({ b }, removed)

        -- ...and b is gone from later frames while a stays
        clear(log)
        em:update(0.016)
        assert.are.same({ "update:a" }, log)
        assert.equals(1, #em:query(function() return true end))
    end)

    it("an entity can remove itself during its own update", function()
        local em = EntityManager.new()
        local log = {}
        local e = ent("e", log)
        e.update = function(self)
            log[#log + 1] = "update:e"
            em:remove(self)
        end
        em:add(e)
        clear(log)

        em:update(0.016)
        assert.are.same({ "update:e", "leave:e" }, log)
    end)

    it("remove() between frames applies on the next update", function()
        local em = EntityManager.new()
        local log = {}
        local e = ent("e", log)
        em:add(e)

        assert.is_true(em:remove(e))
        clear(log)
        em:update(0.016)
        assert.are.same({ "leave:e" }, log)
        assert.is_false(em:remove(e))          -- no longer registered
    end)

    it("re-adding a pending entity cancels the removal", function()
        local em = EntityManager.new()
        local log = {}
        local e = ent("e", log)
        em:add(e)
        em:remove(e)
        em:add(e)

        clear(log)
        em:update(0.016)
        assert.are.same({ "update:e" }, log)   -- no leave: removal was cancelled
    end)

    it("entities added during update start on the next frame", function()
        local em = EntityManager.new()
        local log = {}
        local added = false
        local a = ent("a", log)
        a.update = function()
            log[#log + 1] = "update:a"
            if not added then
                added = true
                em:add(ent("late", log))
            end
        end
        em:add(a)
        clear(log)

        em:update(0.016)
        assert.are.same({ "update:a", "enter:late" }, log)

        clear(log)
        em:update(0.016)
        assert.are.same({ "update:a", "update:late" }, log)
    end)

    it("clear()/reset() leave every entity and empty the registry", function()
        local em = EntityManager.new()
        local log = {}
        em:add(ent("a", log))
        em:add(ent("b", log))

        local removed = {}
        em:on("removed", function(entity) table.insert(removed, entity) end)

        clear(log)
        em:reset()
        assert.are.same({ "leave:a", "leave:b" }, log)
        assert.equals(2, #removed)
        assert.equals(0, #em:query(function() return true end))
    end)

    it("getByTag returns tagged entities in layer order", function()
        local em = EntityManager.new({ layers = { "back", "front" } })
        local log = {}
        local a = ent("a", log)
        a.tags = { "enemy", "flying" }
        local b = ent("b", log)
        b.tags = { "enemy" }
        local c = ent("c", log)

        em:add(c, "front")
        em:add(a, "back")
        em:add(b, "back")

        assert.are.same({ a, b }, em:getByTag("enemy"))
        assert.are.same({ a }, em:getByTag("flying"))
        assert.are.same({}, em:getByTag("nope"))
    end)

    it("query filters with a predicate", function()
        local em = EntityManager.new()
        local log = {}
        local a = ent("a", log); a.hp = 10
        local b = ent("b", log); b.hp = 90
        em:add(a)
        em:add(b)

        local hurt = em:query(function(e) return e.hp < 50 end)
        assert.are.same({ a }, hurt)
    end)

    it("setLayer changes z-order and validates the layer", function()
        local em = EntityManager.new({ layers = { "back", "front" } })
        local log = {}
        local a = ent("a", log)
        local b = ent("b", log)
        em:add(a, "front")
        em:add(b, "back")

        em:setLayer(a, "back")
        clear(log)
        em:update(0.016)
        assert.are.same({ "update:b", "update:a" }, log)

        assert.has_error(function() em:setLayer(a, "nope") end)
    end)

    it("attach/detach store systems under a name and stop updating detached ones", function()
        local em = EntityManager.new()
        local log = {}
        local e = ent("e", log)
        local system = { update = function() log[#log + 1] = "sys" end }

        em:add(e)
        assert.equals(system, em:attach(e, "health", system))
        assert.equals(system, e.health)      -- reachable as entity.<name>

        clear(log)
        em:update(0.016)
        assert.are.same({ "sys", "update:e" }, log)

        assert.equals(system, em:detach(e, "health"))
        assert.is_nil(e.health)
        clear(log)
        em:update(0.016)
        assert.are.same({ "update:e" }, log)
        assert.is_nil(em:detach(e, "health"))
    end)

    it("update ignores non-positive dt but still applies pending removals", function()
        local em = EntityManager.new()
        local log = {}
        local e = ent("e", log)
        em:add(e)
        em:remove(e)
        em:update(0)
        assert.are.same({ "enter:e", "leave:e" }, log)
    end)

end)
