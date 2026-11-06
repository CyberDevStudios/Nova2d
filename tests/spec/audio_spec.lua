local audio = require("src.systems.audio")

local function fakeSource()
    return {
        playing = false,
        stopped = false,
        volume = 1,
        looping = false,
        pitch = 1,
        play = function(self) self.playing = true end,
        stop = function(self) self.playing = false; self.stopped = true end,
        isPlaying = function(self) return self.playing end,
        setVolume = function(self, v) self.volume = v end,
        setLooping = function(self, l) self.looping = l end,
        setPitch = function(self, p) self.pitch = p end,
    }
end

describe("Audio system", function()

    it("plays on a channel applying master × channel × slot volume", function()
        local a = audio.new()
        local src = fakeSource()
        a:play("sfx", src, { volume = 0.5, loop = true })

        assert.is_true(src.playing)
        assert.is_true(src.looping)
        assert.equals(0.5, src.volume)
    end)

    it("errors on an unknown channel", function()
        local a = audio.new()
        local ok = pcall(function() a:play("nope", fakeSource()) end)
        assert.is_false(ok)
    end)

    it("steals the least-recently-used slot when the pool is exhausted", function()
        local a = audio.new({ channels = { sfx = { pool = 1 } } })
        local first, second = fakeSource(), fakeSource()

        a:play("sfx", first)
        a:play("sfx", second)
        assert.is_true(first.stopped)
        assert.is_true(second.playing)
    end)

    it("music() stops whatever is playing on the channel first", function()
        local a = audio.new()
        local first, second = fakeSource(), fakeSource()

        a:music("music", first)
        assert.is_true(first.looping)          -- music loops by default

        a:music("music", second)
        assert.is_true(first.stopped)
        assert.is_true(second.playing)
    end)

    it("fade() ramps the channel volume and fires fade-complete", function()
        local a = audio.new()
        local events = 0
        a:on("fade-complete", function() events = events + 1 end)

        a:fade("sfx", 0, 0.5)
        a:update(0.25)
        assert.is_true(a:getVolume("sfx") < 1)
        assert.is_true(a:getVolume("sfx") > 0)

        a:update(0.5)
        assert.equals(0, a:getVolume("sfx"))
        assert.equals(1, events)
    end)

    it("fires ended when a source finishes and frees the slot", function()
        local a = audio.new()
        local src = fakeSource()
        local ended = {}
        a:on("ended", function(channel, source)
            table.insert(ended, { channel, source })
        end)

        a:play("sfx", src)
        src.playing = false                -- simulate playback reaching the end
        a:update(0.1)
        assert.equals(1, #ended)
        assert.equals("sfx", ended[1][1])
        assert.equals(src, ended[1][2])

        a:update(0.1)                      -- fires once
        assert.equals(1, #ended)
    end)

    it("volume changes are applied to playing sources", function()
        local a = audio.new()
        local src = fakeSource()
        a:play("sfx", src, { volume = 1 })

        a:setVolume("sfx", 0.5)
        assert.equals(0.5, src.volume)

        a:setMasterVolume(0.5)
        assert.equals(0.25, src.volume)
        assert.equals(0.5, a:getMasterVolume())
    end)

    it("stop/stopAll/reset stop playback and restore the master volume", function()
        local a = audio.new()
        local music, sfx = fakeSource(), fakeSource()
        a:music("music", music)
        a:play("sfx", sfx)

        a:setMasterVolume(0.3)
        a:reset()
        assert.is_true(music.stopped)
        assert.is_true(sfx.stopped)
        assert.equals(1, a:getMasterVolume())
    end)

    it("unknown channel is a no-op for volume and fade calls", function()
        local a = audio.new()
        a:setVolume("nope", 0.5)
        a:fade("nope", 0, 1)
        a:stop("nope")
        assert.equals(0, a:getVolume("nope"))
    end)

end)
