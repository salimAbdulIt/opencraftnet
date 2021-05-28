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

local ic = {["x"]=558, ["y"]=7, ["z"]=624}
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

local transposersConfig = {
   {["x"]=0, ["y"]=-1,["z"]=0,["address"]=""   },
   {["x"]=0, ["y"]=-3,["z"]=0,["address"]="0"  },
   {["x"]=2, ["y"]=-3,["z"]=0,["address"]="05" },
   {["x"]=-2,["y"]=-1,["z"]=0,["address"]="041"},
   {["x"]=-2,["y"]=-3,["z"]=0,["address"]="04" },
}

local function init()
    for i, chest in pairs(chests) do
        debugUtils.setBlock(chest.x + ic.x, chest.y + ic.y, chest.z + ic.z, chestName, chestDmg)
    end
    for i, transposer in pairs(transposersConfig) do
        debugUtils.setBlock(transposer.x + ic.x, transposer.y + ic.y, transposer.z + ic.z, transposerName, transposerDmg)
    end
end

function Tests:customizeStorages()
    -- init
    debugUtils.insertItem(ic.x, ic.y, ic.z, 1, "minecraft:diamond", 0, '{display:{Name:"Durex77"}}' , 1)
    -- execute
    transposers:customizeStorages()
    -- assert
    unit.assertValue("minecraft:diamond", debugUtils.getItem(ic.x, ic.y, ic.z, 1).id)
    debugUtils.removeItem(ic.x, ic.y, ic.z, 1)
    local allTransposers = transposers:getAllTransposers()
    for i, tc in pairs(transposersConfig) do
        local componentAddress = debugUtils.getOCComponentAddress(tc.x + ic.x, tc.y + ic.y, tc.z + ic.z)
        unit.assertValue(componentAddress, allTransposers[tc.address].transposer.address)
    end

    local allStorages = transposers:getAllStorages()
    for i, cc in pairs(chests) do
        local key = {}
        key.address = cc.address
        key.side = cc.side
        unit.assertValue("minecraft:chest", allStorages[key].name)

--         debugUtils.insertItem(ic.x + cc.x, ic.y + cc.y, ic.z + cc.z, 1, "minecraft:diamond", 0, nil , 1)
--         unit.assertValue("minecraft:diamond", allTransposers[tc.address].transposer.address)
--         debugUtils.removeItem(ic.x + cc.x, ic.y + cc.y, ic.z + cc.z, 1)
    end
end

init()

unit.runTests(Tests, beforeTest)


