-- Nova2D — frozen entry point. Do not modify.
-- main.lua
-- no tocar

local Gamestate = require "hump.gamestate"
local splash    = require "src.states.splash"
local menu      = require "src.states.menu"
local game      = require "src.states.game"
local pause     = require "src.states.pause"
local credits   = require "src.states.credits"

function love.load()
    Gamestate.registerEvents()
    Gamestate.switch(splash)
end
