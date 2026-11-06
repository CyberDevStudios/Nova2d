local health = require("src.systems.health")

describe("Health system", function()

    it("applies maxHp and iFrameDuration from config", function()
        local h = health.new({ maxHp = 50, iFrameDuration = 0.5 })
        assert.equals(50, h:getMaxHp())
        assert.equals(50, h:getCurrentHp())

        h:takeDamage(10)
        assert.is_true(h:isInvincible())
        h:update(0.25)
        assert.is_true(h:isInvincible())
        h:update(0.3)
        assert.is_false(h:isInvincible())
    end)

    it("damage reduces HP and fires damaged(amount, type)", function()
        local h = health.new({ maxHp = 100, iFrameDuration = 1 })
        local events = {}
        h:on("damaged", function(amount, dmgType)
            table.insert(events, { amount, dmgType })
        end)

        assert.is_true(h:takeDamage(30, "spike"))
        assert.equals(70, h:getCurrentHp())
        assert.are.same({ 30, "spike" }, events[1])
    end)

    it("i-frames block damage until they expire", function()
        local h = health.new({ maxHp = 100, iFrameDuration = 1 })
        h:takeDamage(10)
        assert.is_false(h:takeDamage(10))
        assert.equals(90, h:getCurrentHp())

        h:update(1.1)
        assert.is_false(h:isInvincible())
        assert.is_true(h:takeDamage(10, "generic"))
        assert.equals(80, h:getCurrentHp())
    end)

    it("fires iFramesStart and iFramesEnd around the window", function()
        local h = health.new({ maxHp = 100, iFrameDuration = 0.5 })
        local events = {}
        h:on("iFramesStart", function() table.insert(events, "start") end)
        h:on("iFramesEnd", function() table.insert(events, "end") end)

        h:takeDamage(10)
        h:update(0.5)
        assert.are.same({ "start", "end" }, events)
    end)

    it("death fires died once and locks damage and healing", function()
        local h = health.new({ maxHp = 20 })
        local died = 0
        h:on("died", function() died = died + 1 end)

        assert.is_true(h:takeDamage(20))
        assert.equals(0, h:getCurrentHp())
        assert.is_true(h:isDead())
        assert.equals(1, died)

        assert.is_false(h:takeDamage(10))
        assert.is_false(h:heal(10))
        assert.equals(0, h:getCurrentHp())
    end)

    it("heal clamps to maxHp and returns whether HP changed", function()
        local h = health.new({ maxHp = 100 })
        h:takeDamage(30)

        local healed = {}
        h:on("healed", function(amount) table.insert(healed, amount) end)

        assert.is_true(h:heal(10))
        assert.equals(80, h:getCurrentHp())
        assert.are.same({ 10 }, healed)

        assert.is_true(h:heal(100))          -- clamped to 20 actual
        assert.equals(100, h:getCurrentHp())
        assert.are.same({ 10, 20 }, healed)

        assert.is_false(h:heal(10))          -- already at max, no change
        assert.is_false(h:heal(0))
    end)

    it("setMaxHp re-clamps current HP and ignores values <= 0", function()
        local h = health.new({ maxHp = 100 })
        h:setMaxHp(40)
        assert.equals(40, h:getMaxHp())
        assert.equals(40, h:getCurrentHp())

        h:setMaxHp(0)
        h:setMaxHp(-5)
        assert.equals(40, h:getMaxHp())
    end)

    it("reset restores HP, state and i-frame timer", function()
        local h = health.new({ maxHp = 100, iFrameDuration = 1 })
        h:takeDamage(50)
        h:update(0.2)
        h:reset()
        assert.equals(100, h:getCurrentHp())
        assert.is_false(h:isDead())
        assert.is_false(h:isInvincible())
        assert.equals(0, h:getIFramesRemaining())
    end)

end)
