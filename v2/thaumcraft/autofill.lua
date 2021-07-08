local component = require('component')
local serial = require('serialization')
local shell = require('shell')
local io = require('io')
local fs = require("filesystem")
require('transposers')

local utils = require('utils')
local Lists = require('lists')
ThaumAutofill = {}

function ThaumAutofill:new()
    local obj = {}

    function obj:init()
        self.transposers = Transposers:new()
        self.pedestals = ListStream
            :new(self.transposers:getAllStorages())
            :filter(function (element) return element.outputSide == 1 end)
            :toArray()
    end

    function obj:checkIfResourcesAvailable(items, groupedItems)
        for i, item in pairs (items) do
            local key = item["name"] .. ':' .. item["damage"]
            local itemFromChest = groupedItems[key]

            if (not itemFromChest[1] or itemFromChest[1].size < item.count) then
                error("dont have item")
            end
        end
    end

    function obj:pushItems(items, groupedItems)
        local pedestalsIndex = 1
        for i, item in pairs(items) do
            local itemsFromChest = groupedItems[item["name"] .. ':' .. item["damage"]]
            for j=1,item["count"] do
                print(j,item["count"])
                self.transposers:transferItem("", 1, itemsFromChest[1].index, self.pedestals[pedestalsIndex].address, self.pedestals[pedestalsIndex].outputSide, 1, 1)
                pedestalsIndex = pedestalsIndex + 1
                itemsFromChest[1].size = itemsFromChest[1].size - 1
                if (itemsFromChest[1].size == 0) then
                    table.remove(itemsFromChest,1)
                end
            end
        end
    end

    function obj:fill(items)
        local itemsInStorage = self.transposers:getAllStacks("", 1).getAll()
        local groupedItems = ListStream
            :new(itemsInStorage)
            :map(function(element, index) if (element) then element.index = index end return element end )
            :filter(function(element) return (element) end)
            :groupBy(function(element) return element["name"] .. ':' .. element["damage"], element end)

        self:checkIfResourcesAvailable(items, groupedItems)

        self:pushItems(items, groupedItems)
    end

    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end

local autofill = ThaumAutofill:new()
local diamond = {}
diamond.name = 'minecraft:diamond'
diamond.damage = 0
diamond.count = 2

local coal = {}
coal.name = 'minecraft:coal'
coal.damage = 0
coal.count = 1
autofill:fill({diamond, coal})
