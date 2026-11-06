-- Executes the exact usage patterns published in the docs, so a broken
-- page fails the build:
--   - core-concepts/entities.md — metatable constructor pattern
--   - api/collision-system.md  — ground check enables a jump
--   - api/jump-system.md       — grounded / input / update / apply loop

local stub = require("tests.love_stub")
stub.install()

local collision = require("src.systems.collision")
local jump = require("src.systems.jump")

describe("Documented examples", function()

    it("entities doc: metatable constructors keep instance state independent", function()
        -- The player module exactly as documented
        local Player = {}
        Player.__index = Player

        function Player.new(x, y)
            local self = setmetatable({}, Player)
            self.x = x or 400
            self.y = y or 300
            self.speed = 200
            return self
        end

        function Player:update(dt)
            self.x = self.x + self.speed * dt
        end

        local p1 = Player.new(0, 0)
        local p2 = Player.new(100, 0)
        p1:update(1)

        assert.equals(200, p1.x)
        assert.equals(100, p2.x)              -- instances are independent
        assert.is_nil(rawget(Player, "x"))    -- the module is never modified
    end)

    it("collision doc: ground check enables a jump on a plain table", function()
        local world = collision.new()
        local ground = { x = 0, y = 100, w = 200, h = 20 }
        world:add(ground)

        local player = { x = 10, y = 84, w = 16, h = 16 }
        player.jump = jump.new()
        world:add(player)

        -- The snippet from the Collision docs
        player.jump.grounded = world:check(player, player.x, player.y + 1)
        assert.is_true(player.jump.grounded)

        assert.is_not_nil(player.jump:jump())
    end)

    it("jump doc: grounded / input / update / apply loop runs end to end", function()
        local world = collision.new()
        local ground = { x = 0, y = 100, w = 400, h = 20 }
        world:add(ground)

        local player = { x = 10, y = 70, w = 16, h = 16 }
        local j = jump.new()
        world:add(player)

        local landed = false
        j:on("landed", function() landed = true end)

        -- Fall until the system reports a landing
        local frames = 0
        while not landed and frames < 600 do
            j.grounded = world:check(player, player.x, player.y + 1)
            j:update(1 / 60)
            world:move(player, player.x, player.y + j:getVelocity() * (1 / 60))
            frames = frames + 1
        end
        assert.is_true(landed)

        -- Now jump and verify the player rises
        local yBefore = player.y
        j.grounded = world:check(player, player.x, player.y + 1)
        assert.is_true(j.grounded)
        assert.equals(j.jumpVelocity, j:jump())

        for _ = 1, 5 do
            j.grounded = world:check(player, player.x, player.y + 1)
            j:update(1 / 60)
            world:move(player, player.x, player.y + j:getVelocity() * (1 / 60))
        end
        assert.is_true(player.y < yBefore)
    end)

end)
