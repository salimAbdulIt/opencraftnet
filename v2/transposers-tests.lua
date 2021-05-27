local fs = require('filesystem')
local shell = require('shell')
local unit = require('unit')
local utils = require('utils')
local component = require('component')
local debug = component.debug
require('transposers')

local transposers = Transposers:new()
local Tests = {}

local interfaceCoords = {["x"]= 558, ["y"]=7,["z"]=624}
local chestName = "minecraft:chest"
local chestDmg = 0
local transposerName = "opencomputers:transposer"
local transposerDmg = 0

local chests = {
   {["x"]= 0,["y"]=0,["z"]=0},
   {["x"]= 1,["y"]=-1,["z"]=0},
   {["x"]= 0,["y"]=-2,["z"]=0},
   {["x"]= 1,["y"]=-3,["z"]=0},
   {["x"]= -1,["y"]=-3,["z"]=0},
   {["x"]= 3,["y"]=-3,["z"]=0},
   {["x"]= -3,["y"]=-3,["z"]=0},
   {["x"]= -2,["y"]=-2,["z"]=0},
   {["x"]= 2,["y"]=-2,["z"]=0}
}

local transposers = {
   {["x"]= 0,["y"]=-1,["z"]=0},
   {["x"]= 0,["y"]=-3,["z"]=0},
   {["x"]= 2,["y"]=-3,["z"]=0},
   {["x"]= -2,["y"]=-1,["z"]=0},
   {["x"]= -2,["y"]=-3,["z"]=0},
}
local function init()
    local world = debug.getWorld(0)
    for i, chest in pairs(chests) do
        world.setBlock(chest.x + interfaceCoords.x, chest.y + interfaceCoords.y, chest.z + interfaceCoords.z, chestName, chestDmg)
    end
    for i, transposer in pairs(transposers) do
        world.setBlock(transposer.x + interfaceCoords.x, transposer.y + interfaceCoords.y, transposer.z + interfaceCoords.z, transposerName, transposerDmg)
    end
end

init()
