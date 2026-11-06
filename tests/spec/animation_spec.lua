local stub = require("tests.love_stub")
stub.install()

local animation = require("src.systems.animation")

local function fakeImage()
    return {
        getWidth = function() return 64 end,   -- 4 frames of 16px
        getHeight = function() return 16 end,
    }
end

describe("Animation system", function()

    it("requires image, frameWidth and frameHeight", function()
        assert.has_error(function() animation.new({}) end)
        assert.has_error(function() animation.new({ image = fakeImage() }) end)
        assert.has_error(function()
            animation.new({ image = fakeImage(), frameWidth = 16 })
        end)
    end)

    it("applies config, including loop = false (regression)", function()
        local anim = animation.new({
            image = fakeImage(),
            frameWidth = 16,
            frameHeight = 16,
            fps = 4,
            loop = false,
        })
        assert.is_false(anim.loop)
        assert.is_false(anim._finished)
        assert.is_true(anim:isPlaying())
    end)

    it("selects the configured frames and reports frame dimensions", function()
        local anim = animation.new({
            image = fakeImage(),
            frameWidth = 16,
            frameHeight = 16,
            frames = { 2, 4 },
        })
        assert.equals(2, #anim.anim.frames)
        local w, h = anim:getDimensions()
        assert.equals(16, w)
        assert.equals(16, h)
    end)

    it("advances frames and fires a frame event when the frame changes", function()
        local anim = animation.new({
            image = fakeImage(),
            frameWidth = 16,
            frameHeight = 16,
            frames = { 1, 2, 3, 4 },
            fps = 4,
        })
        local frames = {}
        anim:on("frame", function(position) table.insert(frames, position) end)

        anim:update(0.26)   -- > one frame at 4fps (0.25s each)
        assert.is_true(#frames >= 1)
        assert.equals(anim:getFrame(), frames[#frames])
    end)

    it("fires complete on every cycle when looping", function()
        local anim = animation.new({
            image = fakeImage(),
            frameWidth = 16,
            frameHeight = 16,
            frames = { 1, 2 },
            fps = 10,
            loop = true,
        })
        local complete = 0
        anim:on("complete", function() complete = complete + 1 end)

        anim:update(0.21)   -- one full 0.2s cycle
        assert.equals(1, complete)
        anim:update(0.21)   -- second cycle
        assert.equals(2, complete)
    end)

    it("fires complete exactly once when not looping and stops", function()
        local anim = animation.new({
            image = fakeImage(),
            frameWidth = 16,
            frameHeight = 16,
            frames = { 1, 2 },
            fps = 10,
            loop = false,
        })
        local complete = 0
        anim:on("complete", function() complete = complete + 1 end)

        anim:update(1)
        anim:update(1)
        assert.equals(1, complete)
        assert.is_false(anim:isPlaying())
    end)

    it("pause freezes the frame; resume continues", function()
        local anim = animation.new({
            image = fakeImage(),
            frameWidth = 16,
            frameHeight = 16,
            frames = { 1, 2, 3, 4 },
            fps = 4,
        })
        anim:update(0.26)
        local position = anim:getFrame()
        anim:pause()
        anim:update(1)
        assert.equals(position, anim:getFrame())
        anim:resume()
        anim:update(0.26)
        assert.is_true(anim:getFrame() ~= position or #anim.anim.frames == 1)
    end)

    it("play() restarts a finished non-looping animation", function()
        local anim = animation.new({
            image = fakeImage(),
            frameWidth = 16,
            frameHeight = 16,
            frames = { 1, 2 },
            fps = 10,
            loop = false,
        })
        anim:update(1)
        assert.is_false(anim:isPlaying())

        anim:play()
        assert.is_true(anim:isPlaying())
        assert.equals(1, anim:getFrame())
    end)

    it("stop/reset rewinds to the first frame", function()
        local anim = animation.new({
            image = fakeImage(),
            frameWidth = 16,
            frameHeight = 16,
            frames = { 1, 2, 3, 4 },
            fps = 4,
        })
        anim:update(0.6)
        anim:reset()
        assert.equals(1, anim:getFrame())
        assert.is_false(anim:isPlaying())
    end)

    it("getQuad returns a quad with viewport accessors", function()
        local anim = animation.new({
            image = fakeImage(),
            frameWidth = 16,
            frameHeight = 16,
        })
        local quad = anim:getQuad()
        assert.is_not_nil(quad)
        assert.is_function(quad.getViewport)
        local _, _, w, h = quad:getViewport()
        assert.equals(16, w)
        assert.equals(16, h)
    end)

end)
