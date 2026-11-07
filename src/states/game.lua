-- Nova2D — mini-platformer demo
-- src/states/game.lua
-- Playable sample that wires the framework together: Input, Jump,
-- Collision, Health, Camera, Animation and the EntityManager.
-- Replace it with your own game code — docs/guides/tutorial-platformer.md
-- walks through how it is built.

local Gamestate = require "hump.gamestate"
local Pause = require("src.states.pause")
local VERSION = require("src.version")

local EntityManager = require("src.systems.entitymanager")
local Input = require("src.systems.input")
local Collision = require("src.systems.collision")
local Jump = require("src.systems.jump")
local Health = require("src.systems.health")
local Camera = require("src.systems.camera")
local Animation = require("src.systems.animation")

local Player = require("src.entities.player")
local Hazard = require("src.entities.hazard")

-- ---------------------------------------------------------------------------
-- Level data
-- ---------------------------------------------------------------------------
local LEVEL_W, LEVEL_H = 1600, 600
local SPAWN_X, SPAWN_Y = 64, 544

-- Solid rectangles: { x, y, w, h } — floor with a pit at x = 560..720
local SOLIDS = {
    { 0,    560, 560, 40 },    -- floor, left of the pit
    { 720,  560, 880, 40 },    -- floor, right of the pit
    { 0,    0,   12,  600 },   -- left wall
    { 1588, 0,   12,  600 },   -- right wall
    { 240,  470, 160, 16 },    -- platform A
    { 520,  380, 160, 16 },    -- platform B
    { 960,  460, 200, 16 },    -- platform C
    { 1280, 360, 160, 16 },    -- platform D
}

-- Spike strips: { x, y, w } (12px tall, sitting on the surface below)
local HAZARDS = {
    { x = 400,  y = 548, w = 32 },   -- on the floor
    { x = 1100, y = 548, w = 48 },   -- on the floor
    { x = 980,  y = 448, w = 32 },   -- on platform C
}

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local State = {}
local fonts = {}

-- The Input system installs love.keypressed/keyreleased hooks once per
-- process, so keep a single instance and reuse it across plays.
local inputInstance = nil

function State:enter()
    fonts.text  = love.graphics.newFont(13)
    fonts.small = love.graphics.newFont(11)

    -- Shared systems, owned by the state
    if not inputInstance then
        inputInstance = Input.new({ bufferWindow = 0.1 })
    end
    self.input = inputInstance
    self.world = Collision.new({ cellSize = 64 })
    self.camera = Camera.new({ smoothing = 0.08 })
    self.camera:setBounds(0, 0, LEVEL_W, LEVEL_H)
    self.entities = EntityManager.new({ layers = { "actors", "hazards" } })

    -- Static level geometry lives only in the collision world; it is
    -- drawn directly by this state (no entity needed for plain rects).
    for _, s in ipairs(SOLIDS) do
        self.world:add({ x = s[1], y = s[2], w = s[3], h = s[4] })
    end

    -- Player entity: constructor instance + systems attached through the
    -- manager (reachable as player.jump / player.health / player.animation)
    local player = Player.new(SPAWN_X, SPAWN_Y)
    player.input = self.input
    player.world = self.world
    player.sheet = love.graphics.newImage("assets/images/player.png")

    self.entities:attach(player, "jump", Jump.new({ jumpVelocity = -450 }))
    self.entities:attach(player, "health", Health.new({ maxHp = 100, iFrameDuration = 1 }))
    self.entities:attach(player, "animation", Animation.new({
        image = player.sheet,
        frameWidth = 16,
        frameHeight = 16,
        frames = { 1, 2, 3, 4 },
        fps = 8,
        loop = true,
    }))

    player.health:on("died", function()
        player:respawn(true)
        self.camera:startShake(10, 0.4)
    end)

    self.entities:add(player, "actors")
    self.world:add(player)
    self.player = player

    -- Hazards: loaded into both the entity manager and the collision world
    for _, h in ipairs(HAZARDS) do
        local hazard = Hazard.new(h.x, h.y, h.w)
        self.entities:add(hazard, "hazards")
        self.world:add(hazard)
    end

    -- Damage on contact. Spikes are solid, so bump resolves the move and
    -- fires "collision" — the player takes damage (i-frames limit it).
    self.world:on("collision", function(entity, other)
        if entity ~= player or not other.tags then
            return
        end
        for _, tag in ipairs(other.tags) do
            if tag == "hazard" then
                if player.health:takeDamage(other.damage, "spike") then
                    self.camera:startShake(6, 0.25)
                end
                return
            end
        end
    end)

    self.camera:follow(player)
end

function State:leave()
    self.entities:clear()
    self.world:reset()
    self.player = nil
end

function State:update(dt)
    self.input:update(dt)

    -- Ground probe for the jump system. Attached systems update before
    -- the player, so this must run before entities:update(dt).
    local player = self.player
    player.jump.grounded = self.world:check(player, player.x, player.y + 1)

    self.entities:update(dt)
    self.camera:update(dt)
end

-- ---------------------------------------------------------------------------
-- Draw
-- ---------------------------------------------------------------------------
function State:draw()
    love.graphics.clear(0.055, 0.055, 0.075)

    self.camera:attach()
    self:drawLevel()
    self.entities:draw()
    self.camera:detach()

    self:drawHud()
end

function State:drawLevel()
    love.graphics.setColor(0.18, 0.16, 0.30)
    for _, s in ipairs(SOLIDS) do
        love.graphics.rectangle("fill", s[1], s[2], s[3], s[4], 3)
    end
    love.graphics.setColor(0.30, 0.26, 0.55)
    love.graphics.setLineWidth(2)
    for _, s in ipairs(SOLIDS) do
        love.graphics.rectangle("line", s[1], s[2], s[3], s[4], 3)
    end
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
end

function State:drawHud()
    local player = self.player
    local hp = player.health:getCurrentHp()
    local maxHp = player.health:getMaxHp()

    -- HP bar
    local x, y, w, h = 16, 16, 160, 14
    love.graphics.setColor(1, 1, 1, 0.12)
    love.graphics.rectangle("fill", x, y, w, h, 4)
    love.graphics.setColor(0.49, 0.23, 0.93, 0.9)
    love.graphics.rectangle("fill", x, y, w * (hp / maxHp), h, 4)

    love.graphics.setFont(fonts.text)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.printf(hp .. " / " .. maxHp, x, y - 1, w, "center")

    -- Controls hint
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(1, 1, 1, 0.45)
    love.graphics.printf("Arrows / WASD to move  ·  Space to jump  ·  Esc to pause",
        0, love.graphics.getHeight() - 26, love.graphics.getWidth(), "center")

    -- Framework version — single source of truth (src/version.lua)
    love.graphics.setColor(1, 1, 1, 0.25)
    love.graphics.print("Nova2D v" .. VERSION, 16, love.graphics.getHeight() - 20)

    love.graphics.setColor(1, 1, 1)
end

-- ---------------------------------------------------------------------------
-- Input
-- ---------------------------------------------------------------------------
function State:keypressed(key)
    if key == "escape" then
        Gamestate.push(Pause)
    end
end

return State
