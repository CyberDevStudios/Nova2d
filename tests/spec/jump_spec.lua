local jump = require("src.systems.jump")

local function close(a, b)
    return math.abs(a - b) < 1e-9
end

describe("Jump system", function()

    describe("constructor", function()
        it("applies config values, including boolean false (regression)", function()
            local j = jump.new({ variableHeight = false, maxJumps = 2, gravity = 100 })
            assert.is_false(j.variableHeight)
            assert.equals(2, j.maxJumps)
            assert.equals(100, j.gravity)
        end)

        it("keeps the documented defaults", function()
            local j = jump.new()
            assert.is_true(j.variableHeight)
            assert.equals(800, j.gravity)
            assert.equals(-400, j.jumpVelocity)
            assert.equals(1, j.maxJumps)
        end)
    end)

    it("jumps when grounded and returns the applied velocity", function()
        local j = jump.new()
        j.grounded = true
        j:update(0.016)

        local v = j:jump()
        assert.equals(j.jumpVelocity, v)
        assert.equals(1, j:getJumpsUsed())
    end)

    it("applies gravity while airborne", function()
        local j = jump.new({ gravity = 800 })
        j.grounded = false
        j:update(0.5)
        assert.is_true(close(400, j:getVelocity()))
    end)

    it("fires leftGround / landed and resets jumps on landing", function()
        local j = jump.new()
        local events = {}
        j:on("leftGround", function() table.insert(events, "leftGround") end)
        j:on("landed", function() table.insert(events, "landed") end)

        j.grounded = true
        j:update(0.1)                          -- initial landing
        assert.are.same({ "landed" }, events)

        j:jump()
        j.grounded = false
        j:update(0.1)                          -- left the ground
        assert.are.same({ "landed", "leftGround" }, events)

        j.grounded = true
        j:update(0.1)                          -- landed again
        assert.are.same({ "landed", "leftGround", "landed" }, events)
        assert.equals(0, j:getJumpsUsed())
        assert.equals(0, j:getVelocity())
    end)

    it("allows a jump inside the coyote window after leaving ground", function()
        local j = jump.new({ coyoteTime = 0.1 })
        j.grounded = true
        j:update(0.1)
        j.grounded = false
        j:update(0.05)
        assert.is_true(j:getCoyoteTimeRemaining() > 0)
        assert.is_not_nil(j:jump())
    end)

    it("buffers a jump input and executes it on landing", function()
        local j = jump.new({ bufferTime = 0.2 })
        j.grounded = false
        j:update(0.1)

        assert.is_nil(j:jump())                -- cannot jump: gets buffered
        assert.is_true(j:getBufferTimeRemaining() > 0)

        j.grounded = true
        j:update(0.01)
        assert.is_true(j:getVelocity() < 0)    -- buffered jump executed
        assert.equals(1, j:getJumpsUsed())
    end)

    it("fires jumpBufferExpired when the buffer times out", function()
        local j = jump.new({ bufferTime = 0.1 })
        local expired = 0
        j:on("jumpBufferExpired", function() expired = expired + 1 end)

        j.grounded = false
        j:update(0.05)
        j:jump()                               -- buffered
        j:update(0.2)                          -- buffer expires
        assert.equals(1, expired)
        assert.equals(0, j:getBufferTimeRemaining())
    end)

    it("release() halves upward velocity when variableHeight is on", function()
        local j = jump.new()
        j.grounded = true
        j:update(0.1)
        j:jump()
        j:release()
        assert.equals(j.jumpVelocity * 0.5, j:getVelocity())
        assert.is_false(j._state == "charging")
    end)

    it("release() does nothing when variableHeight is false (regression)", function()
        local j = jump.new({ variableHeight = false })
        j.grounded = true
        j:update(0.1)
        j:jump()
        j:release()
        assert.equals(j.jumpVelocity, j:getVelocity())
    end)

    it("supports multi-jump up to maxJumps", function()
        local j = jump.new({ maxJumps = 2 })
        j.grounded = true
        j:update(0.1)

        assert.is_not_nil(j:jump())            -- first jump
        j.grounded = false
        j:update(0.05)
        assert.is_not_nil(j:jump())            -- second jump, mid-air
        j:update(0.05)
        assert.is_nil(j:jump())                -- out of jumps
        assert.equals(2, j:getJumpsUsed())
    end)

    it("fires jumped with the applied velocity", function()
        local j = jump.new()
        local values = {}
        j:on("jumped", function(v) table.insert(values, v) end)
        j.grounded = true
        j:update(0.1)
        j:jump()
        assert.are.same({ j.jumpVelocity }, values)
    end)

    it("reset returns to the initial state", function()
        local j = jump.new()
        j.grounded = true
        j:update(0.1)
        j:jump()
        j.grounded = false
        j:update(0.1)

        j:reset()
        assert.equals(0, j:getVelocity())
        assert.equals(0, j:getJumpsUsed())
        assert.is_false(j.grounded)
        assert.is_false(j:isGrounded())
    end)

end)
