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
    local countOfChests = 0
    for k, v in pairs(allStorages) do countOfChests = countOfChests + 1 end
    unit.assertValue(#chests, countOfChests)
    for key, chest in pairs(allStorages) do
        local chestInConfig = false
        for i, cc in pairs(chests) do
            if (cc.address == key.address and cc.side == key.side) then
                unit.assertValue("minecraft:chest", chest.name)
                chestInConfig = true
            end
        end
        unit.assertTrue(chestInConfig)
--         debugUtils.insertItem(ic.x + cc.x, ic.y + cc.y, ic.z + cc.z, 1, "minecraft:diamond", 0, nil , 1)
--         unit.assertValue("minecraft:diamond", allTransposers[tc.address].transposer.address)
--         debugUtils.removeItem(ic.x + cc.x, ic.y + cc.y, ic.z + cc.z, 1)
    end
end

function initTransposers()
    transposers.transposerAddresses = {["041"]={inputSide=0},[""]={inputSide=1},["04"]={inputSide=5},["0"]={inputSide=1},["05"]={inputSide=4}}
    for i,tc in pairs(transposersConfig)
        transposers.transposerAddresses[tc.address].transposer = component.proxy(debugUtils.getOCComponentAddress(tc.x + ic.x, tc.y + ic.y, tc.z + ic.z)
    end
    transposers.storageAddresses = {[{address="04",side=1}]={isUsedInTransfers=false,outputSide=1,size=27.0,name="minecraft:chest",address="04",inputSide=5},[{address="04",side=4}]={isUsedInTransfers=false,outputSide=4,size=27.0,name="minecraft:chest",address="04",inputSide=5},[{address="",side=1}]={isUsedInTransfers=false,outputSide=1,size=27.0,name="minecraft:chest",address="",inputSide=0},[{address="",side=0}]={isUsedInTransfers=true,outputSide=0,size=27.0,name="minecraft:chest",address="",inputSide=1},[{address="0",side=4}]={isUsedInTransfers=true,outputSide=4,size=27.0,name="minecraft:chest",address="0",inputSide=1},[{address="05",side=1}]={isUsedInTransfers=false,outputSide=1,size=27.0,name="minecraft:chest",address="05",inputSide=4},[{address="05",side=5}]={isUsedInTransfers=false,outputSide=5,size=27.0,name="minecraft:chest",address="05",inputSide=4},[{address="",side=5}]={isUsedInTransfers=false,outputSide=5,size=27.0,name="minecraft:chest",address="",inputSide=1},[{address="0",side=5}]={isUsedInTransfers=true,outputSide=5,size=27.0,name="minecraft:chest",address="0",inputSide=1}}
end

function Tests:transferItem()
    -- init
    initTransposers()
    for i, cc in pairs(chests) do

--             unit.assertTrue(chestInConfig)
        debugUtils.insertItem(ic.x + cc.x, ic.y + cc.y, ic.z + cc.z, 2, "minecraft:diamond", 0, nil , 2)
        unit.assertValue("minecraft:diamond", debugUtils.getItem(ic.x + cc.x, ic.y + cc.y, ic.z + cc.z, 2).id)
        transposers:transferItem()
        --         debugUtils.removeItem(ic.x + cc.x, ic.y + cc.y, ic.z + cc.z, 1)
        end
    debugUtils.insertItem(ic.x, ic.y, ic.z, 1, "minecraft:diamond", 0, '{display:{Name:"Durex77"}}' , 1)

    -- assert

end
init()

unit.runTests(Tests, beforeTest)


