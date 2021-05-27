local fs = require('filesystem')
local shell = require('shell')
local unit = require('unit')
local utils = require('utils')
local debugUtils = require('debugUtils')
local component = require('component')
local debug = component.debug
require('transposers')

local transposers = Transposers:new()
local Tests = {}

local interfaceCoords = {["x"]=558, ["y"]=7, ["z"]=624}
local chestName = "minecraft:chest"
local chestDmg = 0
local transposerName = "opencomputers:transposer"
local transposerDmg = 0

local chests = {
   {["x"]=0, ["y"]=0, ["z"]=0, ["address"]="",  ["side"]=1},
   {["x"]=1, ["y"]=-1,["z"]=0, ["address"]="",  ["side"]=5},
   {["x"]=0, ["y"]=-2,["z"]=0, ["address"]="",  ["side"]=0},
   {["x"]=1, ["y"]=-3,["z"]=0, ["address"]="0", ["side"]=5},
   {["x"]=-1,["y"]=-3,["z"]=0, ["address"]="0", ["side"]=4},
   {["x"]=3, ["y"]=-3,["z"]=0, ["address"]="05",["side"]=5},
   {["x"]=-3,["y"]=-3,["z"]=0, ["address"]="04",["side"]=4},
   {["x"]=2, ["y"]=-2,["z"]=0, ["address"]="05",["side"]=1},
   {["x"]=-2,["y"]=-2,["z"]=0, ["address"]="04",["side"]=1}
}

local transposers = {
   {["x"]=0, ["y"]=-1,["z"]=0,["address"]=""   },
   {["x"]=0, ["y"]=-3,["z"]=0,["address"]="0"  },
   {["x"]=2, ["y"]=-3,["z"]=0,["address"]="05" },
   {["x"]=-2,["y"]=-1,["z"]=0,["address"]="041"},
   {["x"]=-2,["y"]=-3,["z"]=0,["address"]="04" },
}

local function init()
    for i, chest in pairs(chests) do
        debugUtils.setBlock(chest.x + interfaceCoords.x, chest.y + interfaceCoords.y, chest.z + interfaceCoords.z, chestName, chestDmg)
    end
    for i, transposer in pairs(transposers) do
        debugUtils.setBlock(transposer.x + interfaceCoords.x, transposer.y + interfaceCoords.y, transposer.z + interfaceCoords.z, transposerName, transposerDmg)
    end
end

function Tests:customizeStorages()
    -- init
    debugUtils.insertItem(interfaceCoords.x, interfaceCoords.y, interfaceCoords.z, 1, "minecraft:diamond", 0, nil , 1)
    -- execute

    -- assert

end

init()
