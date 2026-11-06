local stub = require("tests.love_stub")
stub.install()

local camera = require("src.systems.camera")

describe("Camera system", function()

    it("applies config values, including bounds from the constructor (regression)", function()
        local cam = camera.new({
            smoothing = 0.05,
            zoom = 2,
            minZoom = 2,
            maxZoom = 2,
            bounds = { 0, 0, 1600, 600 },
        })
        assert.equals(0.05, cam.smoothing)
        assert.equals(2, cam:getZoom())
        assert.is_not_nil(cam.bounds)
        assert.are.same({ 0, 0, 1600, 600 }, cam.bounds)
    end)

    it("follow() snaps to the target and update() lerps toward it", function()
        local cam = camera.new({ smoothing = 0.1 })
        local target = { x = 1000, y = 500 }
        cam:follow(target)

        local x0, y0 = cam:getPosition()
        assert.equals(1000, x0)
        assert.equals(500, y0)

        target.x, target.y = 900, 400
        for _ = 1, 60 do cam:update(1 / 60) end
        local x1, y1 = cam:getPosition()
        assert.is_true(math.abs(x1 - 900) < 1)
        assert.is_true(math.abs(y1 - 400) < 1)
    end)

    it("follow(nil) stops following", function()
        local cam = camera.new()
        cam:follow({ x = 100, y = 100 })
        cam:follow(nil)
        cam:update(1)
        local x = cam:getPosition()
        assert.equals(100, x)
    end)

    it("clamps the position to the configured bounds", function()
        local cam = camera.new({ bounds = { 0, 0, 1600, 600 } })
        cam:follow({ x = 5000, y = 5000 })
        cam:update(1 / 60)

        local x, y = cam:getPosition()
        assert.equals(1600 - 400, x)   -- right edge, halfW = 800/2 at zoom 1
        assert.equals(600 - 300, y)   -- bottom edge, halfH = 600/2
    end)

    it("setZoom clamps to min/max and reset restores the configured zoom", function()
        local cam = camera.new({ minZoom = 0.5, maxZoom = 2, zoom = 1 })
        cam:setZoom(10)
        assert.equals(2, cam:getZoom())
        cam:setZoom(0.01)
        assert.equals(0.5, cam:getZoom())
        cam:setZoom(1.2)
        cam:reset()
        assert.equals(1, cam:getZoom())
    end)

    it("shake decays over its duration and fires shakeStart/shakeEnd", function()
        local cam = camera.new()
        local events = {}
        cam:on("shakeStart", function() table.insert(events, "start") end)
        cam:on("shakeEnd", function() table.insert(events, "end") end)

        cam:startShake(10, 0.2)
        assert.is_true(cam:isShaking())
        cam:update(0.1)
        assert.is_true(cam:isShaking())
        cam:update(0.15)
        assert.is_false(cam:isShaking())
        assert.are.same({ "start", "end" }, events)
    end)

    it("getViewRect reports the visible world rectangle", function()
        local cam = camera.new()
        cam:follow({ x = 400, y = 300 })
        local x, y, w, h = cam:getViewRect()
        assert.equals(0, x)
        assert.equals(0, y)
        assert.equals(800, w)
        assert.equals(600, h)

        cam:setZoom(2)
        x, y, w, h = cam:getViewRect()
        assert.equals(200, x)
        assert.equals(150, y)
        assert.equals(400, w)
        assert.equals(300, h)
    end)

    it("clearBounds removes the clamping", function()
        local cam = camera.new({ bounds = { 0, 0, 1600, 600 } })
        cam:clearBounds()
        cam:follow({ x = 5000, y = 5000 })
        cam:update(1 / 60)
        local x = cam:getPosition()
        assert.equals(5000, x)
    end)

end)
