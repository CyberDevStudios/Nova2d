local stub = require("tests.love_stub")
stub.install()

local input = require("src.systems.input")

describe("Input system", function()

    before_each(function()
        stub.reset()
    end)

    it("creates default bindings and getBindings returns a copy", function()
        local i = input.new()
        assert.are.same({ "space" }, i:getBindings("jump"))

        local copy = i:getBindings("jump")
        table.insert(copy, "w")
        assert.are.same({ "space" }, i:getBindings("jump"))
        assert.is_nil(i:getBindings("unbound"))
    end)

    it("bind adds keys without duplicates; unbind and rebind update them", function()
        local i = input.new()
        i:bind("jump", "w", "up")
        assert.are.same({ "space", "w", "up" }, i:getBindings("jump"))
        i:bind("jump", "w")
        assert.are.same({ "space", "w", "up" }, i:getBindings("jump"))

        i:unbind("jump", "w")
        assert.are.same({ "space", "up" }, i:getBindings("jump"))
        i:unbind("jump")
        assert.are.same({}, i:getBindings("jump"))

        i:rebind("jump", "w")
        assert.are.same({ "w" }, i:getBindings("jump"))
    end)

    it("isPressed polls the keyboard and isReleased inverts it", function()
        local i = input.new()
        assert.is_false(i:isPressed("left"))
        assert.is_true(i:isReleased("left"))

        stub.pressKey("left")
        assert.is_true(i:isPressed("left"))
        assert.is_false(i:isReleased("left"))
        assert.is_false(i:isPressed("right"))
    end)

    it("getPressedActions lists the held actions", function()
        local i = input.new()
        stub.pressKey("left")
        stub.pressKey("space")
        local pressed = i:getPressedActions()
        table.sort(pressed)
        assert.are.same({ "jump", "left" }, pressed)
    end)

    it("buffers a press within bufferWindow and expires it", function()
        local i = input.new({ bufferWindow = 0.2 })

        -- The module hooks love.keypressed; dispatch a press through it
        love.keypressed("space")
        assert.is_true(i:isBuffered("jump"))

        stub.advance(0.3)
        assert.is_false(i:isBuffered("jump"))
    end)

    it("isBuffered is always false when the buffer is disabled", function()
        local i = input.new({ bufferWindow = 0 })
        love.keypressed("space")
        assert.is_false(i:isBuffered("jump"))
    end)

    it("update trims expired buffer entries", function()
        local i = input.new({ bufferWindow = 0.1 })
        love.keypressed("space")
        stub.advance(0.2)
        i:update(0.2)
        assert.is_false(i:isBuffered("jump"))
    end)

    it("reset clears bindings and buffers", function()
        local i = input.new({ bufferWindow = 0.5 })
        stub.pressKey("space")
        love.keypressed("space")
        i:reset()
        assert.is_nil(i:getBindings("jump"))
        assert.is_false(i:isPressed("jump"))
        assert.is_false(i:isBuffered("jump"))
    end)

    it("works without the joystick module (guarded gamepad check)", function()
        assert.is_nil(rawget(love, "joystick"))
        local i = input.new()
        stub.pressKey("x")                      -- default binding of "action"
        assert.is_true(i:isPressed("action"))   -- no crash without love.joystick
    end)

end)
