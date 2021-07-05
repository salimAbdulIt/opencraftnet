local component = require('component')
local serial = require('serialization')
local shell = require('shell')
local io = require('io')
local fs = require("filesystem")
require('transposers')
require('database')
local utils = require('utils')
local Lists = require('lists')
StorageSystem = {}

function ThaumAutofill:new()
    local obj = {}

    function obj:isItemsInStorage(storage, items)
        local combinedItems = {}
        for item in (items) do
            --combinedItems
        end
    end

    function obj:init()
        self.transposers = Transposers:new()
        self.pedestals = ListStream
            :new(self.transposers:getAllStorages())
            :filter(function (element) return element.outputSide == 1 end)
            :toArray()
    end

    function obj:checkIfResourcesAvailable(items, groupedItems)
        for item in (items) do
            local key = item["name"] .. ':' .. item["damage"]
            local itemFromChest = groupedItems[key]

            if (not itemFromChest or itemFromChest.count < item.count) then
                error("dont have item")
            end
        end
    end

    function obj:pushItems(items, groupedItems)
        for item, i in pairs(items) do
            local itemsFromChest = groupedItems[item["name"] .. ':' .. item["damage"]]
            for j=1,item["count"] do
                self.transposers:transferItem("", 1, itemFromChest[j].index, self.pedestals[i].address, self.pedestals[i].outputSide, 1)
            end
        end
    end

    function obj:fill(items)
        local itemsInStorage = self.transposers:getAllStacks("", 1).getAll()
        local groupedItems = ListStream
            :new(itemsInStorage)
            :map(function(element, index) { if (element) then element.index = index end return element end })
            :filter(function(element) return (element) end)
            :groupBy(function(element) return element["name"] .. ':' .. element["damage"], element end)

        self:checkIfResourcesAvailable(items, groupedItems)

        self:pushItems(items, groupedItems)
    end

    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
