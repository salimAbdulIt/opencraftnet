local component = require('component')
local serial = require('serialization')
local shell = require('shell')
local io = require('io')
local fs = require("filesystem")
require('transposers')
require('db')
local utils = require('utils')
StorageSystem = {}
function StorageSystem:new()
    local obj = {}

    function obj:init()
        self.db = DurexDatabase:new("ITEMS")
        self.transposers = Transposers:new()
        self.idOfAvailableSlot = 'minecraftair_0.0'
    end

    function obj:getAllItems(skip, limit, orderBy)
        return self.db:select(nil, orderBy, skip, limit)
    end

    function obj:getAllItemsByLabel(label, skip, limit, orderBy)
        local clause = self:dbClause("label", label, "STARTFROM")
        return self.db:select({ clause }, orderBy, skip, limit)
    end

    function obj:setNameToItem(id, damage, name)
        local itemID = self:getDbId(id, damage)
        local clause = self:dbClause("ID", itemID, "=")
        local itemsFromDb = self.db:select({ clause })
        itemsFromDb[1].label = name
        self.db:insert(itemID, itemsFromDb[1])
    end

    function obj:getDbId(id, damage)
        return (id .. "_" .. damage):gsub(":", "")
    end

    function obj:getItemsFromRow(rows, count)
        local returnList = {}
        if (rows and next(rows)) then
            local row = rows[1]
            for i, ix in pairs(row.itemXdata) do
                for j, jx in pairs(row.itemXdata[i]) do
                    for k, kx in pairs(row.itemXdata[i][j]) do

                        local usedCount = 0
                        repeat
                            local item = {}
                            item.storage = i
                            item.side = j
                            item.slot = k
                            item.storageType = row.itemXdata[i][j][k].storageType
                            if (not count) then
                                item.size = 0
                            else
                                local countOfItemsOnSlot = row.itemXdata[i][j][k].size - usedCount
                                local flag = false
                                if (countOfItemsOnSlot > row.maxSize) then
                                    flag = true
                                    countOfItemsOnSlot = row.maxSize
                                end
                                if (count > countOfItemsOnSlot) then
                                    item.size = countOfItemsOnSlot
                                    count = count - countOfItemsOnSlot
                                else
                                    item.size = count
                                    count = 0
                                end
                            end
                            table.insert(returnList, item)
                        until (not flag or not count or count == 0)
                        if (count == 0) then
                            return returnList
                        end
                    end
                end
            end
        end
        if (not count) then
            return returnList
        end
        return
    end

    function obj:dbClause(fieldName, fieldValue, typeOfClause)
        local clause = {}
        clause.column = fieldName
        clause.value = fieldValue
        clause.operation = typeOfClause
        return clause
    end

    function obj:getItem(id, damage, count, stopLevel)
        local itemID = self.getDbId(id, damage)
        local itemsFromDb = self.db:select({ self:dbClause("ID", itemID, "=") })
        local availableSlotsFromDb = self.db:select({ self:dbClause("ID", self.idOfAvailableSlot, "=") })
        local slots = getItemsFromRow(itemsFromDb, count)
        if not slots then
            return
        end
        local availableSlots = getAvailableSlotsOfInputOutput()
        if (#slots > #availableSlots) then
            error("Not enough space")
        end
        for i = 1, #slots do
            local slot = slots[i]
            getItemFromStorage(slot.storage, slot.side, slot.slot, slot.storageType, slot.size, nil, stopLevel) --todo investigate nil value
            local oldCountOfItems = itemsFromDb[1].itemXdata[slot.storage][slot.side][slot.slot].size
            itemsFromDb[1].itemXdata[slot.storage][slot.side][slot.slot].size = itemsFromDb[1].itemXdata[slot.storage][slot.side][slot.slot].size - slot.size
            itemsFromDb[1].count = itemsFromDb[1].count - slot.size
            if (itemsFromDb[1].itemXdata[slot.storage][slot.side][slot.slot].size == 0) then
                itemsFromDb[1].itemXdata[slot.storage][slot.side][slot.slot] = nil
                local value = {}
                value.size = 0
                if (not availableSlotsFromDb[1].itemXdata[slot.storage]) then
                    availableSlotsFromDb[1].itemXdata[slot.storage] = {}
                end
                if (not availableSlotsFromDb[1].itemXdata[slot.storage][slot.side]) then
                    availableSlotsFromDb[1].itemXdata[slot.storage][slot.side] = {}
                end
                availableSlotsFromDb[1].itemXdata[slot.storage][slot.side][slot.slot] = value
            end
        end
        db:execute("INSERT INTO ITEMS " .. getDbId(id, damage), itemsFromDb[1])
        db:execute("INSERT INTO ITEMS " .. id_of_available_slot, availableSlotsFromDb[1])
    end

    function obj:sinkItemsWithStorages() -- todo scan one by one (I mean one chest per once)
        local allItems = self:getAllItems()
        for i = 1, #allItems do
            allItems[i].count = 0
            allItems[i].itemXdata = {}
        end
        local items = {}
        for k, v in pairs(allItems) do
            items[self.getDbId(v.name, v.damage)] = v
        end
        allItems = nil
        for address, storage in pairs(self.storageAddresses) do
            if (self.transposerAddresses[storage.address].transposer.getInventorySize(storage.outputSide) ~= nil) then
                local itemsOfStorage = self.transposerAddresses[storage.address].transposer.getAllStacks(storage.outputSide).getAll()
                local startIndex = 1
                if (storage.ignoreFirstSlot) then
                    startIndex = 2
                end
                for k = startIndex, #itemsOfStorage do -- remove +1 in case if u are using 1.12.2
                    local v = itemsOfStorage[k] -- remove -1 in case if u are using 1.12.2
                    if (not v or not next(v)) then
                        v.name = 'minecraft:air'
                        v.damage = 0
                        v.label = 'minecraft:air'
                        v.size = 0
                        v.maxSize = 0
                    end
                    local id = self.getDbId(v.name, v.damage)
                    if (not items[id]) then

                        local newItem = {}
                        newItem.name = v.name
                        newItem.damage = v.damage
                        newItem.maxSize = v.maxSize
                        newItem.label = v.label
                        newItem.count = 0
                        newItem.itemXdata = {}
                        items[id] = newItem
                    end
                    items[id].maxSize = v.maxSize -- remove it
                    items[id].count = items[id].count + v.size

                    if (not items[id].itemXdata[storage.address]) then items[id].itemXdata[storage.address] = {} end
                    if (not items[id].itemXdata[storage.address][storage.outputSide]) then items[id].itemXdata[storage.address][storage.outputSide] = {} end
                    if (not items[id].itemXdata[storage.address][storage.outputSide][k]) then items[id].itemXdata[storage.address][storage.outputSide][k] = {} end

                    local itemXdata = {}
                    itemXdata.size = v.size
                    items[id].itemXdata[storage.address][storage.outputSide][k] = itemXdata
                end
            end
        end

        for k, v in pairs(items) do
            self.db:insert(k, v) --todo maybe do insert all or patches
        end
    end

    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
