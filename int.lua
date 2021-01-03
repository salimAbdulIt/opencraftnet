local component = require("component")
local computer = require("computer")
local event = require("event")
local term = require("term")
local shell = require("shell")
local fs = require("filesystem")
local unicode = require("unicode")
local serial = require("serialization")
local gpu = component.gpu
local data = component.database
local tunnel

if (component.isAvailable('tunnel')) then
    tunnel = component.tunnel
end

require("durexdb")
local db = Database:new()

local transposerAddresses = {}
local storageAddresses = {}
local robotAddress = {}
local storageDrawersAddress = {}
storageDrawersAddress['items'] = {}

local items = {}
gpu.setResolution(80, 30)

local page = 1
local sizeOfPage = 26
local items_on_the_screen = {}
local id_of_available_slot = 'minecraftair_0.0'
local nameOfRobot = 'opencomputers:robot'
local nameOfChest = 'tile.chest'
local order = {}
local storages = { ["tile.IronChest"] = 'storage', ["ironchest:iron_chest"] = 'storage', ["tile.storage"] = 'storage', ['opencomputers:robot'] = 'robot', ["tile.chest"] = 'storage' }
local findNameFilter

local revercedAddresses = {}
revercedAddresses[0] = 1
revercedAddresses[1] = 0
revercedAddresses[2] = 3
revercedAddresses[3] = 2
revercedAddresses[4] = 5
revercedAddresses[5] = 4
function reverceAddress(address)
    return revercedAddresses[address]
end

function say(msg)
    if (component.isAvailable('chat_box')) then
        component.chat_box.setName('Storage')
        component.chat_box.say(msg)
    end
end

db:read()
function loadStorages()
    if require("filesystem").exists(shell.getWorkingDirectory() .. "/storages.lua") then
        local file = io.open(shell.getWorkingDirectory() .. "/storages.lua", "r")
        local address = serial.unserialize(file:read(999999))
        transposerAddresses = {} --todo fix
        for i = 1, #address do
            transposerAddresses[i] = component.proxy(address[i])
        end
        file:close()
    end
end

function saveStorages()
    local file = io.open(shell.getWorkingDirectory() .. "/storages.lua", "w")
    local address = {}
    for i = 1, #transposerAddresses do
        address[i] = transposerAddresses[i].address --todo fix
    end
    file:write(serial.serialize(address))
    file:close()
end

local tempStorages = component.list('transposer')
local tempTransposers = {}
for k, v in pairs(tempStorages) do
    tempTransposers[k] = component.proxy(k)
end
os.sleep(1)

function isStorage(transposer)
    return (transposer and ((not storages[transposer]) or storages[transposer] == 'storage'))
end

function isRobot(transposer)
    return (storages[transposer] == 'robot')
end

function isDrawerStorage(transposer)
    return (storages[transposer] == 'storageDrawers')
end

function findEnd(address, lastOutputTransposer)
    local returnedValue = false
    for inputSide = 0, 5 do
        for k, tcomponent in pairs(tempTransposers) do
            local item = tcomponent.getStackInSlot(inputSide, 1)
            if (item and item.label == 'Durex77' and isStorage(tcomponent.getInventoryName(inputSide))
                    and lastOutputTransposer ~= tcomponent.address) then
                transposerAddresses[address] = {}
                transposerAddresses[address].transposer = tcomponent
                transposerAddresses[address].inputSide = inputSide
                for outputSide = 0, 5 do
                    if (inputSide ~= outputSide) then
                        local outputSideInventoryName = transposerAddresses[address].transposer.getInventoryName(outputSide)
                        if (isStorage(outputSideInventoryName)) then
                            -- found storage
                            returnedValue = true
                            local address1 = {}
                            address1.address = address
                            address1.side = outputSide
                            storageAddresses[address1] = {}
                            storageAddresses[address1].name = outputSideInventoryName
                            storageAddresses[address1].address = address
                            storageAddresses[address1].outputSide = outputSide
                            storageAddresses[address1].inputSide = inputSide
                            storageAddresses[address1].ignoreFirstSlot = false
                            if (transposerAddresses[address].transposer.transferItem(inputSide, outputSide, 64, 1, 1) ~= 0) then
                                if (findEnd(address .. outputSide, transposerAddresses[address].transposer.address)) then
                                    storageAddresses[address1].ignoreFirstSlot = true
                                end
                                transposerAddresses[address].transposer.transferItem(outputSide, inputSide, 64, 1, 1)
                            end
                        elseif (isDrawerStorage(outputSideInventoryName)) then
                            returnedValue = true
                            storageDrawersAddress.address = address
                            storageDrawersAddress.outputSide = outputSide
                            storageDrawersAddress.inputSide = inputSide
                            storageDrawersAddress.drawer = component.drawer
                            storageDrawersAddress.chestSide = 'UP'
                        elseif (isRobot(outputSideInventoryName)) then
                            returnedValue = true
                            robotAddress.address = address
                            robotAddress.outputSide = outputSide
                            robotAddress.inputSide = inputSide
                        end
                    end
                end
            end
        end
    end
    return returnedValue
end

function ItemToString(name, dmg)
    local item = {}
    item.name = name
    item.dmg = dmg
    return serial.serialize(item)
end

local sortFunc = function(a, b)
    return a[2] - b[2]
end

function createSelectQuery(limit, skip, labelName, orderBy)
    local selectQuery = "SELECT FROM ITEMS LIMIT " .. limit .. " SKIP " .. skip
    if (labelName and labelName ~= '') then
        local finalName = labelName:gsub(" ", "___")
        selectQuery = selectQuery .. " WHERE label STARTFROM " .. finalName
    end

    if (orderBy) then
        selectQuery = selectQuery .. " ORDER BY " .. orderBy
    end
    return selectQuery
end


function drawItems()
    items_on_the_screen = db:execute(createSelectQuery(sizeOfPage, (page - 1) * sizeOfPage, findNameFilter, "count"), nil)
    gpu.setBackground(0x111111)
    gpu.fill(23, 3, 56, 27, ' ')
    for i = 1, #items_on_the_screen do
        if i % 2 == 1 then
            gpu.setBackground(0x333333)
        else
            gpu.setBackground(0x555555)
        end
        gpu.setForeground(0xffffff)
        gpu.fill(25, i + 2, 52, 1, ' ')
        gpu.set(25, i + 2, items_on_the_screen[i].label)
        gpu.set(60, i + 2, tostring(items_on_the_screen[i].count))
        gpu.setForeground(0x00ff00)
        gpu.set(74, i + 2, 'Get')
        gpu.setForeground(0xff0000)
        gpu.set(73, i + 2, 'N')
        if (items_on_the_screen[i].receipt) then
            gpu.setForeground(0x00ff00)
            gpu.set(72, i + 2, 'C')
        end
    end
end


function drawInterface()
    gpu.setBackground(0xbbbbbb)
    term.clear()
    gpu.setBackground(0x111111)
    gpu.fill(3, 2, 19, 4, ' ')
    gpu.fill(23, 2, 56, 28, ' ')
    gpu.setForeground(0xffffff)
    gpu.fill(3, 27, 9, 3, ' ')
    gpu.set(5, 28, '<----')
    gpu.fill(13, 27, 9, 3, ' ')
    gpu.set(15, 28, '---->')
    gpu.setForeground(0xff0000)
    gpu.set(25, 2, 'Name')
    gpu.set(60, 2, 'Count')
    gpu.set(72, 2, 'Query')
    gpu.setForeground(0xffffff)
    gpu.fill(3, 23, 19, 3, ' ')
    gpu.set(7, 24, 'Clear chest')
    gpu.fill(3, 19, 19, 3, ' ')
    gpu.fill(3, 15, 19, 3, ' ')
    gpu.set(7, 16, 'Scan chests')
    gpu.fill(3, 11, 19, 3, ' ')
    gpu.fill(3, 7, 19, 3, ' ')
    gpu.set(7, 20, 'Add Craft')
    gpu.set(5, 8, 'Find')
    drawItems()
end


function getAllItemsFromDataBase(from, to)
    return dataBase:getAllItems(from, to)
end

function getAllItemsFromDataBaseAll()
    return dataBase:getAllItems(1, 500)
end

function setFilter(name)
    findNameFilter = name
end

function saveItems()
    local file = io.open(shell.getWorkingDirectory() .. "/Chest.lua", "w")
    file:write(serial.serialize(items))
    file:close()
end

function uncompressRow(row)
    if (not (row.name == 'minecraft:air')) then
        return
    end
    for i, ix in pairs(row.itemXdata) do
        for j, jx in pairs(row.itemXdata[i]) do
            for k, kx in pairs(row.itemXdata[i][j]) do
                local cache = {}
                if (type(k) == 'string') then
                    for word in string.gmatch(k, '([^,]+)') do
                        for word2 in string.gmatch(word, '([^-]+)') do
                            table.insert(cache, word2)
                        end
                    end
                    if (#cache > 1) then
                        for ind = 1, #cache do
                            row.itemXdata[i][j][tonumber(cache[ind])] = kx
                        end
                        row.itemXdata[i][j][k] = nil
                    end
                end
            end
        end
    end
end

function compressRow(row)
    if (not (row.name == 'minecraft:air')) then
        return
    end
    for i, ix in pairs(row.itemXdata) do
        for j, jx in pairs(row.itemXdata[i]) do
            local cache = {}
            for k, kx in pairs(row.itemXdata[i][j]) do
                local key = serial.serialize(row.itemXdata[i][j][k])
                if (not cache[key]) then cache[key] = {} end

                table.insert(cache[key], k)
            end
            local tempValue = {}
            for k, v in pairs(cache) do
                table.sort(v)
                local finalIds = {}
                local first
                local last
                for ind = 1, #v do
                    if (not first) then
                        first = v[ind]
                        last = v[ind]
                    elseif (last + 1) == v[ind] then
                        last = v[ind]
                    elseif (last and last - first > 1) then
                        table.insert(finalIds, first .. '-' .. last)
                        first = v[ind]
                        last = v[ind]
                    elseif (first == last) then
                        table.insert(finalIds, first)
                        first = v[ind]
                        last = v[ind]
                    else
                        table.insert(finalIds, first)
                        table.insert(finalIds, last)
                        first = v[ind]
                        last = v[ind]
                    end
                end
                if (first == last) then
                    table.insert(finalIds, first)
                elseif (last - first > 1) then
                    table.insert(finalIds, first .. '-' .. last)
                else
                    table.insert(finalIds, first)
                    table.insert(finalIds, last)
                end
                local id = table.concat(finalIds, ',')
                tempValue[id] = row.itemXdata[i][j][v[1]]
            end
            row.itemXdata[i][j] = tempValue
        end
    end
end

function sinkItemsWithStorages()
    local allItems = db:execute("SELECT FROM ITEMS")
    for i = 1, #allItems do
        allItems[i].count = 0
        allItems[i].itemXdata = {}
    end
    local items = {}
    for k, v in pairs(allItems) do
        if (not v.maxSize) then --todo remove it
            v.maxSize = 64
        end
        items[getDbId(v.name, v.damage)] = v
    end
    allItems = nil
    for address, storage in pairs(storageAddresses) do
        if (transposerAddresses[storage.address].transposer.getInventorySize(storage.outputSide) ~= nil) then
            local itemsOfStorage = transposerAddresses[storage.address].transposer.getAllStacks(storage.outputSide).getAll()
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
                local id = getDbId(v.name, v.damage)
                if (not items[id]) then
                    items[id] = {}
                    items[id].name = v.name
                    items[id].damage = v.damage
                    items[id].maxSize = v.maxSize
                    items[id].label = v.label
                    items[id].count = 0
                    items[id].itemXdata = {}
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

    if (storageDrawersAddress.address) then
        local drawerStorageItems = storageDrawersAddress.drawer.getAllStacks()
        for i, v in pairs(drawerStorageItems) do
            local tempItem = drawerStorageItems[i].all()
            local id = getDbId(tempItem.id, tempItem.dmg)
            if (not items[id]) then
                items[id] = {}
                items[id].name = tempItem.id
                items[id].damage = tempItem.dmg
                items[id].maxSize = tempItem.max_size
                items[id].label = tempItem.display_name
                items[id].count = 0
                items[id].itemXdata = {}
            end
            local itemXdata = {}
            itemXdata.size = storageDrawersAddress.drawer.getItemCount((i - 1) / 2)
            storageDrawersAddress['items'][getDbId(tempItem.id, tempItem.dmg)] = itemXdata.size
            items[id].count = items[id].count + itemXdata.size
            items[id].drawer = true
            itemXdata.storageType = 'drawer'
            itemXdata.maxSize = storageDrawersAddress.drawer.getMaxCapacity((i - 1) / 2)
            if (not items[id].itemXdata[storageDrawersAddress.address]) then items[id].itemXdata[storageDrawersAddress.address] = {} end
            if (not items[id].itemXdata[storageDrawersAddress.address][storageDrawersAddress.outputSide]) then items[id].itemXdata[storageDrawersAddress.address][storageDrawersAddress.outputSide] = {} end
            if (not items[id].itemXdata[storageDrawersAddress.address][storageDrawersAddress.outputSide][(i - 1) / 2]) then items[id].itemXdata[storageDrawersAddress.address][storageDrawersAddress.outputSide][(i - 1) / 2] = {} end

            items[id].itemXdata[storageDrawersAddress.address][storageDrawersAddress.outputSide][(i - 1) / 2] = itemXdata
        end
    end
    for k, v in pairs(items) do
        compressRow(v)
        db:execute("INSERT INTO ITEMS " .. k, v)
    end
end


function transferItemOut(storageX, side, fromSlot, count, toSlot)
    local storage = transposerAddresses[storageX]
    if (toSlot) then
        storage.transposer.transferItem(side, storage.inputSide, count, fromSlot, toSlot)
    else
        storage.transposer.transferItem(side, storage.inputSide, count, fromSlot)
    end
end

function getAvailableSlotsOfInputOutput()
    local itemsOfStorage = transposerAddresses[""].transposer.getAllStacks(1).getAll() --todo change 1 to inputSide
    local availableSlots = {}
    for k = 1, #itemsOfStorage do
        local v = itemsOfStorage[k]
        if (v.name == "minecraft:air") then
            table.insert(availableSlots, k)
        end
    end
    return availableSlots
end

function getItemFromStorage(storageX, side, fromSlot, storageType, count, toSlot, stopLevel)
    if (storageType == 'drawer') then
        storageDrawersAddress.drawer.pushItem(storageDrawersAddress.chestSide, 1 + fromSlot * 2, count)
        getItemFromSlot(storageX, side, 1, count, toSlot, stopLevel)
    else
        getItemFromSlot(storageX, side, fromSlot, count, toSlot, stopLevel)
    end
end

function getItemFromSlot(storageX, side, fromSlot, count, toSlot, stopLevel)
    local transferToSlot = 1
    if (#storageX == 0) then
        transferToSlot = toSlot
    end
    if (stopLevel and stopLevel > #storageX) then
        transposerAddresses[storageX].transposer.transferItem(side, side, count, fromSlot, 1) --todo change 1 to toSlot
    else
        transferItemOut(storageX, side, fromSlot, count, transferToSlot)
    end
    local itemFromStorage = transposerAddresses[storageX].transposer.getStackInSlot(side, fromSlot)

    local remainedItem = {}

    if (#storageX > 0 and not (stopLevel and #storageX == stopLevel)) then
        remainedItem = getItemFromSlot(storageX:sub(1, #storageX - 1), tonumber(storageX:sub(#storageX, #storageX)), 1, count, toSlot, stopLevel)
    else
        remainedItem.storage = storageX
        remainedItem.side = side
        remainedItem.index = fromSlot
        if (itemFromStorage) then
            remainedItem.size = itemFromStorage.size
        else
            remainedItem.size = 0
        end
    end
    if (not itemFromStorage) then
        itemFromStorage = {}
        itemFromStorage.size = 0
    end
    return itemFromStorage
end

function setNameToItem(id, damage, name)
    local itemsFromDb = db:execute("SELECT FROM ITEMS WHERE ID = " .. getDbId(id, damage), nil)
    itemsFromDb[1].label = name
    db:execute("INSERT INTO ITEMS " .. getDbId(id, damage), itemsFromDb[1])
    db:save()
end

function getDbId(id, damage)
    return (id .. "_" .. damage):gsub(":", "")
end

function getItemsFromRow(rows, count)
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

function getItem(id, damage, count, stopLevel)
    local itemsFromDb = db:execute("SELECT FROM ITEMS WHERE ID = " .. getDbId(id, damage), nil)
    local availableSlotsFromDb = db:execute("SELECT FROM ITEMS WHERE ID = " .. id_of_available_slot, nil)
    uncompressRow(availableSlotsFromDb[1])
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
    compressRow(availableSlotsFromDb[1])
    db:execute("INSERT INTO ITEMS " .. id_of_available_slot, availableSlotsFromDb[1])
end

function transferItemTo(id, dmg, count, toAddress, toSide, toIndex)
    local sameAddressLetters = 1
    --    for i=1,string.len(fromAddress)  -- todo calculate sameAddressLetters
    --        if (not (fromAddress:sub(i,i) == toAddress(i,i))) then
    --            break
    --        end
    --        sameAddressLetters = i
    --    end
    getItem(id, dmg, count, sameAddressLetters)
    transferItemBack(1, toAddress, toSide, toIndex, count, sameAddressLetters)
end

function transferItemBack(slot, address, side, index, count, level)
    local sourceSide = 1
    local storage = transposerAddresses[address:sub(0, level)]
    if (level ~= 0) then
        sourceSide = storage.inputSide
    end
    if (level < #address) then
        storage.transposer.transferItem(sourceSide, tonumber(address:sub(level + 1, level + 1)), count, slot, 1)
        return transferItemBack(1, address, side, index, count, level + 1)
    else
        transposerAddresses[address].transposer.transferItem(sourceSide, side, count, slot, index)
        local tempItem = transposerAddresses[address].transposer.getStackInSlot(side, index)
        local item = {}
        item.storage = address
        item.side = side
        item.slot = index
        item.size = tempItem.size
        item.maxSize = tempItem.maxSize
        item.name = tempItem.name
        item.label = tempItem.label
        item.damage = tempItem.damage
        return item
    end
end

function getDrawerSlots(name, damage)
    local itemsFromDb = db:execute("SELECT FROM ITEMS WHERE ID = " .. getDbId(name, damage))
    local returnList = {}
    if (not itemsFromDb[1]) then
        return returnList
    end
    local row = itemsFromDb[1]
    for i, ix in pairs(row.itemXdata) do
        for j, jx in pairs(row.itemXdata[i]) do
            for k, kx in pairs(row.itemXdata[i][j]) do
                if (row.itemXdata[i][j][k].drawer) then
                    local item = {}
                    item.storage = i
                    item.side = j
                    item.slot = k
                    item.size = row.itemXdata[i][j][k].size
                    item.maxSize = row.itemXdata[i][j][k].maxSize
                    table.insert(returnList, item)
                end
            end
        end
    end
    return returnList
end

function getNotFullSlots(name, damage, maxSize)
    local itemsFromDb = db:execute("SELECT FROM ITEMS WHERE ID = " .. getDbId(name, damage))
    local returnList = {}
    if (not itemsFromDb[1]) then
        return returnList
    end
    local row = itemsFromDb[1]
    for i, ix in pairs(row.itemXdata) do
        for j, jx in pairs(row.itemXdata[i]) do
            for k, kx in pairs(row.itemXdata[i][j]) do
                if (row.itemXdata[i][j][k].size < maxSize) then
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

local craftSlots = {
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 5,
    [5] = 6,
    [6] = 7,
    [7] = 9,
    [8] = 10,
    [9] = 11,
    [0] = 13
}

function pushItems(index, fromAddress)
    local itemsFromDb = db:execute("SELECT FROM ITEMS WHERE ID = " .. id_of_available_slot, nil)
    uncompressRow(itemsFromDb[1])

    local availableSlots = getItemsFromRow(itemsFromDb, nil)
    local items = {}
    local caret = 1
    local startIndex = 1
    local endIndex = transposerAddresses[""].transposer.getInventorySize(1)
    if (not fromAddress) then
        fromAddress = ""
    end
    if (index) then
        startIndex = index
        endIndex = index
    end
    if (not fromLevel) then
        fromLevel = 0
    end
    for i = startIndex, endIndex do
        local tempItem = transposerAddresses[fromAddress].transposer.getStackInSlot(1, i)
        if (tempItem) then

            if (storageDrawersAddress.address and storageDrawersAddress['items'][getDbId(tempItem.name, tempItem.damage)]) then
                local slots = getDrawerSlots(tempItem.name, tempItem.damage)
                local flag = true
                for j = 1, #slots do
                    local count = tempItem.maxSize - transposerAddresses[slots[j].storage].transposer.getStackInSlot(slots[j].side, slots[j].slot).size
                    table.insert(items, transferItemBack(i, slots[j].storage, slots[j].side, slots[j].slot, count, #fromAddress))
                    tempItem.size = tempItem.size - count
                    if (tempItem.size <= 0) then
                        flag = false
                        break
                    end
                end
            end

            if (tempItem.size < tempItem.maxSize) then
                transposerAddresses[""].transposer.store(1, i, data.address, 1)
                local slots = getNotFullSlots(tempItem.name, tempItem.damage, tempItem.maxSize)
                local flag = true
                for j = 1, #slots do
                    if (transposerAddresses[slots[j].storage].transposer.compareStackToDatabase(slots[j].side, slots[j].slot, data.address, 1, true)) then
                        local count = tempItem.maxSize - transposerAddresses[slots[j].storage].transposer.getStackInSlot(slots[j].side, slots[j].slot).size
                        table.insert(items, transferItemBack(i, slots[j].storage, slots[j].side, slots[j].slot, count, fromLevel))
                        tempItem.size = tempItem.size - count
                        if (tempItem.size <= 0) then
                            flag = false
                            break
                        end
                    end
                end
                if flag then
                    local slot = availableSlots[caret]
                    caret = caret + 1
                    table.insert(items, transferItemBack(i, slot.storage, slot.side, slot.slot, 64, 0))
                end
            else
                local slot = availableSlots[caret]
                caret = caret + 1
                table.insert(items, transferItemBack(i, slot.storage, slot.side, slot.slot, 64, 0))
            end
        end
    end

    for i = 1, caret - 1 do
        itemsFromDb[1].itemXdata[availableSlots[i].storage][availableSlots[i].side][availableSlots[i].slot] = nil
    end
    compressRow(itemsFromDb[1])
    db:execute("INSERT INTO ITEMS " .. id_of_available_slot, itemsFromDb[1])

    local itemsToSave = {}
    for i = 1, #items do
        local id = getDbId(items[i].name, items[i].damage)

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
            itemToSave = db:execute("SELECT FROM ITEMS WHERE ID = " .. id)[1]
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
        db:execute("INSERT INTO ITEMS " .. k, v)
    end
end


function craft(name, damage, count)
    recursiveCraft(name, damage, count)
    return true
end

function countRecipeItems(recipe)
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


local deep = 0
function recursiveCraft(name, damage, requestedCount)
    local craftedItem = db:execute("SELECT FROM ITEMS WHERE ID = " .. getDbId(name, damage), nil)[1]

    if (not craftedItem) then
        say("I dont know this item" .. name .. ' ' .. damage)
        return false
    end
    deep = deep + 1
    local recipe = craftedItem.receipt
    if recipe == nil then


        say("I dont have receipt for " .. name .. ' ' .. damage)
        return false
    end
    local items = countRecipeItems(recipe)
    local n = math.ceil(requestedCount / recipe[0].count):: recount::
    local maxSize = math.min(n, craftedItem.maxSize, math.floor(craftedItem.maxSize / recipe[0].count))
    local ok = true

    for itemId, nStacks in pairs(items) do
        local item = db:execute("SELECT FROM ITEMS WHERE ID = " .. getDbId(itemId.name, itemId.damage), nil)[1]
        if (not item) then
            say("I dont know this item" .. itemId.name .. ' ' .. itemId.damage)
            return false
        end
        local nedded = nStacks * n
        local itemCount = item.count
        if itemCount < nedded then
            if not recursiveCraft(item.name, item.damage, nedded - itemCount) then
                ok = false
                break
            end
            goto recount
        end
        maxSize = math.min(item.maxSize, maxSize)
    end
    if ok then
        ok = craftItem(name, damage, n, maxSize, recipe)
        if ok then
        else
        end
    end
    deep = deep - 1
    return ok
end

function craftItem(name, damage, inCount, maxSize, receipt)
    local inStep = maxSize
    while inCount > 0 do
        local n = inStep
        if inCount < n then
            n = inCount
        end
        for i = 1, 9, 1 do
            local itemId = receipt[i]
            if itemId ~= nil then
                --                getItem(itemId.name, itemId.damage, n)
                --                transferItemBack(1, robotAddress.address, robotAddress.outputSide, craftSlots[i], n, 0)
                transferItemTo(itemId.name, itemId.damage, n, robotAddress.address, robotAddress.outputSide, craftSlots[i])
            end
        end

        tunnel.send(64)
        os.sleep(1)
        getItemFromStorage(robotAddress.address, robotAddress.outputSide, craftSlots[0], 'robot', 64, nil, 1)
        pushItems(1, "0")

        inCount = inCount - n
    end
    return true
end

local craftSlotsInChest = { 1, 2, 3, 13, 14, 15, 25, 26, 27 }
function addCraft()
    local receipt = {}
    for i = 1, 9 do
        local tempItem = transposerAddresses[""].transposer.getStackInSlot(1, craftSlotsInChest[i])
        if (tempItem) then
            receipt[i] = {}
            receipt[i].name = tempItem.name
            receipt[i].damage = tempItem.damage
            receipt[i].count = tempItem.size
            transferItemBack(craftSlotsInChest[i], robotAddress.address, robotAddress.outputSide, craftSlots[i], 64, 0)
        end
    end
    tunnel.send(64)
    os.sleep(1)
    local craftedItem = transposerAddresses[robotAddress.address].transposer.getStackInSlot(robotAddress.outputSide, craftSlots[0])
    if (craftedItem) then
        receipt[0] = {}
        receipt[0].name = craftedItem.name
        receipt[0].damage = craftedItem.damage
        receipt[0].count = craftedItem.size

        local item = db:execute("SELECT FROM ITEMS WHERE ID = " .. getDbId(receipt[0].name, receipt[0].damage))[1] --todo crashes in case if crafted item is not exists in the database.
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
        db:execute("INSERT INTO ITEMS " .. getDbId(item.name, item.damage), item)
    end
    db:save()
    getItemFromStorage(robotAddress.address, robotAddress.outputSide, craftSlots[0], 'robot', 64)
end

function findByName()
    gpu.setBackground(0xbbbbbb)
    gpu.setForeground(0xff0000)
    gpu.fill(4, 8, 16, 1, ' ')
    local str = ''
    while true do
        local _, _, asci = event.pull('key_down')
        if (asci == 13) then
            setFilter(str)
            page = 1
            drawItems()
            break
        elseif (asci == 8) then
            gpu.fill(4, 8, 15, 1, ' ')
            str = unicode.sub(str, 1, unicode.len(str) - 1)
            gpu.set(4, 8, str)
        elseif (asci ~= 0) then
            str = str .. unicode.char(asci)
            gpu.set(4, 8, str)
        end
    end
end

findEnd("", -1)
--loadStorages()
drawInterface()
--sinkItemsWithStorages()
drawItems()
function isClicked(x1, y1, x2, y2, x, y)
    return (x >= x1 and y >= y1 and x <= x2 and y <= y2)
end

while true do
    local e, c, x, y, _, p = event.pull(3)
    if e == 'touch' then
        if (isClicked(3, 27, 11, 29, x, y)) then
            if (page > 1) then
                page = page - 1
            end
            drawItems()
        elseif (isClicked(13, 27, 21, 29, x, y)) then
            page = page + 1
            drawItems()
        elseif (isClicked(3, 23, 21, 25, x, y)) then
            pushItems()
            drawItems()
        elseif (isClicked(74, 3, 76, 2 + sizeOfPage, x, y)) then
            if (items_on_the_screen[y - 2]) then

                local damage = items_on_the_screen[y - 2].damage
                local id = items_on_the_screen[y - 2].name
                gpu.setBackground(0xbbbbbb)
                gpu.fill(28, 10, 24, 8, ' ')
                gpu.setBackground(0x111111)
                gpu.fill(30, 11, 20, 6, ' ')
                gpu.setForeground(0xffffff)
                gpu.set(35, 11, "Max count")
                gpu.set(37, 12, tostring(items_on_the_screen[y - 2].count))
                gpu.set(34, 14, "Input count")
                gpu.setBackground(0x666666)
                gpu.setForeground(0xffffff)
                gpu.fill(37, 15, 5, 1, ' ')
                local str = ''
                while true do
                    local _, _, asci = event.pull('key_down')
                    if (asci == 13) then
                        if (str == '' or tonumber(str) == 0) then
                            drawItems()
                            break
                        else
                            getItem(id, damage, tonumber(str))
                            drawItems()
                            break
                        end
                    elseif (asci == 8) then
                        gpu.fill(37, 15, 5, 1, ' ')
                        str = unicode.sub(str, 1, unicode.len(str) - 1)
                        gpu.set(37, 15, str)
                    elseif (asci >= 48 and asci <= 57) then
                        str = str .. unicode.char(asci)
                        gpu.set(37, 15, str)
                    end
                end
            end
        elseif (isClicked(72, 3, 72, 2 + sizeOfPage, x, y)) then
            if (items_on_the_screen[y - 2]) then

                local damage = items_on_the_screen[y - 2].damage
                local id = items_on_the_screen[y - 2].name
                gpu.setBackground(0xbbbbbb)
                gpu.fill(28, 10, 24, 8, ' ')
                gpu.setBackground(0x111111)
                gpu.fill(30, 11, 20, 6, ' ')
                gpu.setForeground(0xffffff)
                gpu.set(34, 14, "Input count")
                gpu.setBackground(0x666666)
                gpu.setForeground(0xffffff)
                gpu.fill(37, 15, 5, 1, ' ')
                local str = ''
                while true do
                    local _, _, asci = event.pull('key_down')
                    if (asci == 13) then
                        if (str == '' or tonumber(str) == 0) then
                            drawItems()
                            break
                        else
                            craft(id, damage, tonumber(str))
                            drawItems()
                            break
                        end
                    elseif (asci == 8) then
                        gpu.fill(37, 15, 5, 1, ' ')
                        str = unicode.sub(str, 1, unicode.len(str) - 1)
                        gpu.set(37, 15, str)
                    elseif (asci >= 48 and asci <= 57) then
                        str = str .. unicode.char(asci)
                        gpu.set(37, 15, str)
                    end
                end
            end
        elseif (isClicked(73, 3, 73, 2 + sizeOfPage, x, y)) then
            local damage = items_on_the_screen[y - 2].damage
            local id = items_on_the_screen[y - 2].name
            if (y - 2) % 2 == 1 then
                gpu.setBackground(0x333333)
            else
                gpu.setBackground(0x555555)
            end
            gpu.fill(25, y, 32, 1, ' ')
            local str = ''
            while true do
                local _, _, asci = event.pull('key_down')
                if (asci == 13) then
                    if (str == '') then
                        drawItems()
                        break
                    else
                        setNameToItem(id, damage, str)
                        drawItems()
                        break
                    end
                elseif (asci == 8) then
                    gpu.fill(25, y, 32, 1, ' ')
                    str = unicode.sub(str, 1, unicode.len(str) - 1)
                    gpu.set(25, y, str)
                elseif (asci ~= 0) then
                    str = str .. unicode.char(asci)
                    gpu.set(25, y, str)
                end
            end
        elseif (isClicked(3, 19, 21, 21, x, y)) then
            addCraft()
        elseif (isClicked(3, 15, 21, 17, x, y)) then
            sinkItemsWithStorages()
            drawInterface()
        elseif (isClicked(3, 11, 21, 13, x, y)) then
            drawInterface()
        elseif (isClicked(3, 7, 21, 9, x, y)) then
            findByName()
        end
    elseif (e == 'slot_click') then
        getClickedItems(c, x)
    end
end
