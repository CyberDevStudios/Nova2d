local collision = require("src.systems.collision")

describe("Collision system", function()

    describe("geometry helpers", function()
        it("box/overlaps/contains behave as documented", function()
            local a = collision.box(0, 0, 10, 10)
            local b = collision.box(5, 5, 10, 10)
            assert.are.same({ x = 0, y = 0, w = 10, h = 10 }, a)
            assert.is_true(collision.overlaps(a, b))
            assert.is_true(collision.overlaps(b, a))
            assert.is_false(collision.overlaps(a, collision.box(11, 0, 5, 5)))

            assert.is_true(collision.contains(a, 0, 0))
            assert.is_true(collision.contains(a, 10, 10))
            assert.is_false(collision.contains(a, 10.5, 5))
        end)
    end)

    describe("world", function()
        local function makeWorld()
            local world = collision.new()
            local player = { x = 0, y = 0, w = 10, h = 10 }
            local wall = { x = 20, y = 0, w = 10, h = 40 }
            world:add(player)
            world:add(wall)
            return world, player, wall
        end

        it("move resolves collisions, fires events and writes back x/y", function()
            local world, player, wall = makeWorld()
            local hits = {}
            world:on("collision", function(entity, other)
                table.insert(hits, { entity, other })
            end)

            local x, y, collided = world:move(player, 40, 0)
            assert.is_true(collided)
            assert.equals(10, x)          -- flush against the wall (20 - width 10)
            assert.equals(10, player.x)
            assert.equals(0, y)
            assert.equals(1, #hits)
            assert.equals(player, hits[1][1])
            assert.equals(wall, hits[1][2])
        end)

        it("check reports collisions without moving or firing events", function()
            local world, player = makeWorld()
            local hits = 0
            world:on("collision", function() hits = hits + 1 end)

            assert.is_true(world:check(player, 40, 0))
            assert.is_false(world:check(player, 0, 100))
            assert.equals(0, player.x)
            assert.equals(0, hits)
        end)

        it("update() teleports without events", function()
            local world, player = makeWorld()
            local hits = 0
            world:on("collision", function() hits = hits + 1 end)

            player.x = 100
            world:update(player)
            assert.equals(0, hits)
            -- the world knows about the new position
            local found = world:queryPoint(105, 5)
            assert.equals(1, #found)
            assert.equals(player, found[1])
        end)

        it("writes back to entity.collider when present", function()
            local world = collision.new()
            local boss = { x = 0, y = 0, collider = { x = 0, y = 0, w = 10, h = 10 } }
            world:add(boss)

            local x, y = world:move(boss, 5, 7)
            assert.equals(5, boss.collider.x)
            assert.equals(7, boss.collider.y)
            assert.equals(0, boss.x)      -- plain fields untouched when collider is used
            assert.equals(5, x)
            assert.equals(7, y)
        end)

        it("query returns entities overlapping a rectangle", function()
            local world, player, wall = makeWorld()
            local found = world:query(-5, -5, 20, 20)
            assert.equals(1, #found)
            assert.equals(player, found[1])

            found = world:query(0, 0, 100, 100)
            assert.equals(2, #found)
        end)

        it("queryPoint returns entities under a point", function()
            local world, player, wall = makeWorld()
            local found = world:queryPoint(5, 5)
            assert.equals(1, #found)
            assert.equals(player, found[1])
            assert.equals(0, #world:queryPoint(200, 200))
        end)

        it("remove and reset clear the world", function()
            local world, player, wall = makeWorld()
            world:remove(wall)
            assert.equals(0, #world:query(15, 0, 20, 40))

            world:reset()
            assert.equals(0, #world:query(-100, -100, 1000, 1000))
            assert.equals(0, world:queryPoint(5, 5)[1] and 1 or 0)
        end)
    end)

end)
