local component = require('component')
local serial = require('serialization')
local shell = require('shell')
local io = require('io')
local fs = require("filesystem")
require('transposers')
require('database')
local utils = require('utils')
StorageSystem = {}
function StorageSystem:new()
    local obj = {}

    function obj:init()
        self.db = DurexDatabase:new("ITEMS")
        self.transposers = Transposers:new()
        local storages = self.transposers:getAllStorages()
        for address, storage in pairs (storages) do
            if (storage.size == 82) then
                self.robotAddress = address
            end
        end
        self.idOfAvailableSlot = 'minecraftair_0'
        self.craftSlotsInChest = { 1, 2, 3, 10, 11, 12, 19, 20, 21 }
        self.craftSlots = {[1] = 5, [2] = 6, [3] = 7, [4] = 9, [5] = 10, [6] = 11, [7] = 13, [8] = 14, [9] = 15, [0] = 17}
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
                        local item = {}
                        item.storage = i
                        item.side = j
                        item.slot = k
                        item.storageType = row.itemXdata[i][j][k].storageType
                        if (not count) then
                            item.size = row.itemXdata[i][j][k].size
                            table.insert(returnList, item)
                        else
                            local countOfItemsOnSlot = row.itemXdata[i][j][k].size
                            if (count > countOfItemsOnSlot) then
                                item.size = countOfItemsOnSlot
                                count = count - countOfItemsOnSlot
                                table.insert(returnList, item)
                            else
                                item.size = count
                                table.insert(returnList, item)
                                return returnList
                            end
                        end
                    end
                end
            end
        end
        return returnList
    end

    function obj:dbClause(fieldName, fieldValue, typeOfClause)
        local clause = {}
        clause.column = fieldName
        clause.value = fieldValue
        clause.operation = typeOfClause
        return clause
    end

    function obj:getAvailableSlotsOfInputOutput()
        local availableSlots = {}
        local allStacks = self.transposers:getAllStacks("", 1).getAll()
        for i, item in pairs(allStacks) do
            if (item.name == 'minecraft:air') then
                table.insert(availableSlots, i)
            end
        end
        return availableSlots
    end

    function obj:getItemTo(id, damage, count, addressTo, sideTo, slotTo)
        local itemID = self:getDbId(id, damage)
        local itemsFromDb = self.db:select({ self:dbClause("ID", itemID, "=") })
        local availableSlotsFromDb = self.db:select({ self:dbClause("ID", self.idOfAvailableSlot, "=") })
        local slots = self:getItemsFromRow(itemsFromDb, count)
        if not slots then
            return
        end
        for i = 1, #slots do
            local slot = slots[i]
            self.transposers:transferItem(slot.storage, slot.side, slot.slot, addressTo, sideTo, slotTo, slot.size)
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
        self.db:insert(self:getDbId(id, damage), itemsFromDb[1])
        self.db:insert(self.idOfAvailableSlot, availableSlotsFromDb[1])
    end

    function obj:getItem(id, damage, count)
        self:getItemTo(id, damage, count, "", 1, nil)
    end

    function obj:sinkItemsWithStorages() -- todo scan one by one (I mean one chest per once)
        local allItems = self:getAllItems()
        for i = 1, #allItems do
            allItems[i].count = 0
            allItems[i].itemXdata = {}
        end
        local items = {}
        for k, v in pairs(allItems) do
            items[self:getDbId(v.name, v.damage)] = v
        end
        allItems = nil
        local storages = self.transposers:getAllStorages()
        for address, storage in pairs (storages) do
            if (storage.size == 82) then
                self.robotAddress = address
            elseif (not (address.address == "" and address.side == 1)) then
                local itemsOfStorage = self.transposers:getAllStacks(address.address, address.side).getAll()
                local startIndex = 1
                if (storage.isUsedInTransfers) then
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
                    local id = self:getDbId(v.name, v.damage)
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

    function obj:addCraft()
        local receipt = {}
        local allStacksFromStorage = self.transposers:getAllStacks("", 1).getAll()
        for i = 1, 9 do
            local tempItem = allStacksFromStorage[self.craftSlotsInChest[i]]
            if (tempItem and tempItem.name ~= "minecraft:air") then
                receipt[i] = {}
                receipt[i].name = tempItem.name
                receipt[i].damage = tempItem.damage
                receipt[i].count = tempItem.size
                self.transposers:transferItem("", 1, self.craftSlotsInChest[i], self.robotAddress.address, self.robotAddress.side, self.craftSlots[i], 64)
            end
        end
        component.tunnel.send(64)
        os.sleep(1)
        local craftedItem = self.transposers:getStackInSlot(self.robotAddress.address, self.robotAddress.side, self.craftSlots[0])
        if (craftedItem) then
            receipt[0] = {}
            receipt[0].name = craftedItem.name
            receipt[0].damage = craftedItem.damage
            receipt[0].count = craftedItem.size
            local key = self:getDbId(receipt[0].name, receipt[0].damage)
            local item = self.db:select({ self:dbClause("ID", key, "=") })[1]
            if (not item) then
                item = {}
                item.name = craftedItem.name
                item.damage = craftedItem.damage
                item.maxSize = craftedItem.maxSize
                item.label = craftedItem.label
                item.count = 0
                item.itemXdata = {}
            end
            item.receipt = receipt
            self.db:insert(key, item)
        end
        self.transposers:transferItem(self.robotAddress.address, self.robotAddress.side, self.craftSlots[0], "", 1, nil, 64)
    end

    function obj:getNotFullSlots(row) --todo reuse getItemsFromRow
        local returnList = {}
        if (not row) then
            return returnList
        end
        for i, ix in pairs(row.itemXdata) do
            for j, jx in pairs(row.itemXdata[i]) do
                for k, kx in pairs(row.itemXdata[i][j]) do
                    if (row.itemXdata[i][j][k].size < row.maxSize) then
                        local item = {}
                        item.storage = i
                        item.side = j
                        item.slot = k
                        item.size = row.itemXdata[i][j][k].size
                        table.insert(returnList, item)
                    end
                end
            end
        end
        return returnList
    end

    function obj:craftItem(name, damage, inCount, maxSize, receipt)
        while inCount > 0 do
            n = math.min(inCount, maxSize)
            for i = 1, 9, 1 do
                local itemId = receipt[i]
                if itemId ~= nil then
                    self:getItemTo(itemId.name, itemId.damage, n, self.robotAddress.address, self.robotAddress.side, self.craftSlots[i])
                end
            end

            component.tunnel.send(64)
            os.sleep(1)
            self:moveItemIntoSystem(self.robotAddress.address, self.robotAddress.side, self.craftSlots[0])

            inCount = inCount - n
        end
        return true
    end

    function obj:countRecipeItems(recipe)
        local counts = {}
        for i = 1, 9 do
            local id = recipe[i]
            if id ~= nil then
                local cnt
                for k, v in pairs(counts) do
                    if (id.name == k.name and id.damage == k.damage) then
                        counts[k] = v + 1
                        cnt = 1
                        break
                    end
                end
                if cnt == nil then
                    counts[id] = 1
                end
            end
        end
        return counts
    end

    function obj:say(msg)
        if (component.isAvailable('chat_box')) then
            component.chat_box.setName('Storage')
            component.chat_box.say(msg)
        else
            print(msg)
        end
    end

    function obj:craft(name, damage, requestedCount)
        self:craftRec(name, damage, requestedCount)
        obj:getItem(name, damage, requestedCount)
    end

    function obj:craftRec(name, damage, requestedCount)
        local craftedItem = self.db:select({ self:dbClause("ID", self:getDbId(name, damage), "=") })[1] --todo inline method and reuse previously selected data

        if (not craftedItem) then
            self:say("Нету вещи " .. name .. ' ' .. damage)
            return false
        end
        local recipe = craftedItem.receipt
        if recipe == nil then
            self:say("Нету вещи " .. craftedItem.label)
            return false
        end
        local items = self:countRecipeItems(recipe)
        local n = math.ceil(requestedCount / recipe[0].count):: recount::
        local maxSize = math.min(n, craftedItem.maxSize, math.floor(craftedItem.maxSize / recipe[0].count))
        local ok = true

        for itemId, nStacks in pairs(items) do
            local item = self.db:select({ self:dbClause("ID", self:getDbId(itemId.name, itemId.damage)) })[1]
            if (not item) then
                self:say("Нету вещи " .. item.label)
                return false
            end
            local nedded = nStacks * n
            local itemCount = item.count
            if itemCount < nedded then
                if not self:craftRec(item.name, item.damage, nedded - itemCount) then
                    ok = false
                    break
                end
                goto recount
            end
            maxSize = math.min(item.maxSize, maxSize)
        end
        if ok then
            ok = self:craftItem(name, damage, n, maxSize, recipe)
            if ok then
            else
            end
        end
        return ok
    end

    function obj:moveItemIntoSystem(address, side, slot) -- todo remove duplicate code
        local availableSlotsFromDb = self.db:select({ self:dbClause("ID", self.idOfAvailableSlot, "=") })
        local availableSlots = self:getItemsFromRow(availableSlotsFromDb, nil)
        local item = self.transposers:getStackInSlot(address, side, slot)
        if (item.name == "minecraft:air") then
            return
        end
        local items = {}
        local caret = 1
        if (item.size < item.maxSize) then
            self.transposers:store(address, side, slot, component.database.address, 1)
            local itemsFromDb = self.db:select({ self:dbClause("ID", self:getDbId(item.name, item.damage), "=") })
            local notFullSlots = self:getNotFullSlots(itemsFromDb[1])
            for j = 1, #notFullSlots do
                 if (self.transposers:compareStackToDatabase(notFullSlots[j].storage, notFullSlots[j].side, notFullSlots[j].slot, component.database.address, 1, true)) then
                     local count = item.maxSize - notFullSlots[j].size
                     self.transposers:transferItem(address, side, slot, notFullSlots[j].storage, notFullSlots[j].side, notFullSlots[j].slot, count)
                     notFullSlots[j].size = notFullSlots[j].size + math.min(count, item.size)
                     notFullSlots[j].name = itemsFromDb[1].name
                     notFullSlots[j].damage = itemsFromDb[1].damage
                     notFullSlots[j].maxSize = itemsFromDb[1].maxSize
                     table.insert(items, notFullSlots[j])
                     item.size = item.size - count
                     if (item.size <= 0) then
                        break
                     end
                end
            end
        end
        if item.size > 0 then
            local availableSlot = availableSlots[caret]
            caret = caret + 1
            self.transposers:transferItem(address, side, slot, availableSlot.storage, availableSlot.side, availableSlot.slot, item.size)
            item.storage = availableSlot.storage
            item.side = availableSlot.side
            item.slot = availableSlot.slot
            table.insert(items, item)
        end


        for i = 1, caret - 1 do
            availableSlotsFromDb[1].itemXdata[availableSlots[i].storage][availableSlots[i].side][availableSlots[i].slot] = nil
        end
        self.db:insert(self.idOfAvailableSlot, availableSlotsFromDb[1])

        local itemsToSave = {}
        for i = 1, #items do
            local id = self:getDbId(items[i].name, items[i].damage)

            local itemToSave = itemsToSave[id]
            if (itemToSave) then
                local countToIncrease = items[i].size
                if (not itemToSave.itemXdata[items[i].storage]) then itemToSave.itemXdata[items[i].storage] = {} end
                if (not itemToSave.itemXdata[items[i].storage][items[i].side]) then itemToSave.itemXdata[items[i].storage][items[i].side] = {} end
                if (not itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot]) then
                    itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot] = {}
                else
                    countToIncrease = countToIncrease - itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot].size
                end
                itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot].size = items[i].size
                itemToSave.count = itemToSave.count + countToIncrease
            else
                itemToSave = self.db:select({ self:dbClause("ID", id, "=") })[1]
                local countToIncrease = items[i].size
                if (not itemToSave) then
                    itemToSave = {}
                    itemToSave.count = 0
                end
                if (not itemToSave.itemXdata) then itemToSave.itemXdata = {} end
                if (not itemToSave.itemXdata[items[i].storage]) then itemToSave.itemXdata[items[i].storage] = {} end
                if (not itemToSave.itemXdata[items[i].storage][items[i].side]) then itemToSave.itemXdata[items[i].storage][items[i].side] = {} end
                if (not itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot]) then
                    itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot] = {}
                else
                    countToIncrease = countToIncrease - itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot].size
                end

                itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot].size = items[i].size
                itemToSave.name = items[i].name
                itemToSave.damage = items[i].damage
                if (not itemToSave.label) then
                    itemToSave.label = items[i].label
                end
                itemToSave.maxSize = items[i].maxSize
                itemToSave.count = itemToSave.count + countToIncrease
                itemsToSave[id] = itemToSave
            end
        end

        for k, v in pairs(itemsToSave) do
            self.db:insert(k, v)
        end
    end

    function obj:cleanOutputStorage()
        local availableSlotsFromDb = self.db:select({ self:dbClause("ID", self.idOfAvailableSlot, "=") })
        local availableSlots = self:getItemsFromRow(availableSlotsFromDb, nil)
        local items = {}
        local caret = 1
        local itemsFromStorage = self.transposers:getAllStacks("", 1).getAll()
        for i, item in pairs(itemsFromStorage) do
            if (item.name ~= "minecraft:air") then
                if (item.size < item.maxSize) then
                    self.transposers:store("", 1, i, component.database.address, 1)
                    local itemsFromDb = self.db:select({ self:dbClause("ID", self:getDbId(item.name, item.damage), "=") })
                    local notFullSlots = self:getNotFullSlots(itemsFromDb[1])
                    for j = 1, #notFullSlots do
                        if (self.transposers:compareStackToDatabase(notFullSlots[j].storage, notFullSlots[j].side, notFullSlots[j].slot, component.database.address, 1, true)) then
                            local count = item.maxSize - notFullSlots[j].size
                            self.transposers:transferItem("", 1, i, notFullSlots[j].storage, notFullSlots[j].side, notFullSlots[j].slot, count)
                            notFullSlots[j].size = notFullSlots[j].size + math.min(count, item.size)
                            notFullSlots[j].name = itemsFromDb[1].name
                            notFullSlots[j].damage = itemsFromDb[1].damage
                            notFullSlots[j].maxSize = itemsFromDb[1].maxSize
                            table.insert(items, notFullSlots[j])
                            item.size = item.size - count
                            if (item.size <= 0) then
                                break
                            end
                        end
                    end
                end
                if item.size > 0 then
                    local availableSlot = availableSlots[caret]
                    caret = caret + 1
                    self.transposers:transferItem("", 1, i, availableSlot.storage, availableSlot.side, availableSlot.slot, item.size)
                    item.storage = availableSlot.storage
                    item.side = availableSlot.side
                    item.slot = availableSlot.slot
                    table.insert(items, item)
                end
            end
        end


        for i = 1, caret - 1 do
            availableSlotsFromDb[1].itemXdata[availableSlots[i].storage][availableSlots[i].side][availableSlots[i].slot] = nil
        end
        self.db:insert(self.idOfAvailableSlot, availableSlotsFromDb[1])

        local itemsToSave = {}
        for i = 1, #items do
            local id = self:getDbId(items[i].name, items[i].damage)

            local itemToSave = itemsToSave[id]
            if (itemToSave) then
                local countToIncrease = items[i].size
                if (not itemToSave.itemXdata[items[i].storage]) then itemToSave.itemXdata[items[i].storage] = {} end
                if (not itemToSave.itemXdata[items[i].storage][items[i].side]) then itemToSave.itemXdata[items[i].storage][items[i].side] = {} end
                if (not itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot]) then
                    itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot] = {}
                else
                    countToIncrease = countToIncrease - itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot].size
                end
                itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot].size = items[i].size
                itemToSave.count = itemToSave.count + countToIncrease
            else
                itemToSave = self.db:select({ self:dbClause("ID", id, "=") })[1]
                local countToIncrease = items[i].size
                if (not itemToSave) then
                    itemToSave = {}
                    itemToSave.count = 0
                end
                if (not itemToSave.itemXdata) then itemToSave.itemXdata = {} end
                if (not itemToSave.itemXdata[items[i].storage]) then itemToSave.itemXdata[items[i].storage] = {} end
                if (not itemToSave.itemXdata[items[i].storage][items[i].side]) then itemToSave.itemXdata[items[i].storage][items[i].side] = {} end
                if (not itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot]) then
                    itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot] = {}
                else
                    countToIncrease = countToIncrease - itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot].size
                end

                itemToSave.itemXdata[items[i].storage][items[i].side][items[i].slot].size = items[i].size
                itemToSave.name = items[i].name
                itemToSave.damage = items[i].damage
                if (not itemToSave.label) then
                    itemToSave.label = items[i].label
                end
                itemToSave.maxSize = items[i].maxSize
                itemToSave.count = itemToSave.count + countToIncrease
                itemsToSave[id] = itemToSave
            end
        end

        for k, v in pairs(itemsToSave) do
            self.db:insert(k, v)
        end
    end

    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
