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


require("durexdb")
local db = Database:new()
local transposerAddresses = {}
local storageAddresses = {}
local robotAddress = {}
local items = {}
gpu.setResolution(80, 30)

local page = 1
local sizeOfPage = 26
local items_on_the_screen = {}
local id_of_available_slot = 'minecraftair_0'
local nameOfRobot = 'opencomputers:robot'

local order = {}


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

function findEnd(address, lastOutputTransposer)
    for inputSide = 0, 5 do
        for k, tcomponent in pairs(tempTransposers) do
            if (tcomponent.getStackInSlot(inputSide, 1) and tcomponent.getInventoryName(inputSide) == 'minecraft:chest'
                    and lastOutputTransposer ~= tcomponent.address) then
                transposerAddresses[address] = {}
                transposerAddresses[address].transposer = tcomponent
                transposerAddresses[address].inputSide = inputSide
                for outputSide = 0, 5 do
                    if (inputSide ~= outputSide) then
                        if (transposerAddresses[address].transposer.getInventoryName(outputSide) == 'minecraft:chest') then
                            transposerAddresses[address].transposer.transferItem(inputSide, outputSide, 64, 1, 1)
                            findEnd(address .. outputSide, transposerAddresses[address].transposer.address)
                            transposerAddresses[address].transposer.transferItem(outputSide, inputSide, 64, 1, 1)
                        elseif (transposerAddresses[address].transposer.getInventoryName(outputSide) == nameOfRobot) then
                            robotAddress.address = address
                            robotAddress.outputSide = outputSide
                            robotAddress.inputSide = inputSide
                        else
                            -- found storage
                            local address1 = {}
                            address1.address = address
                            address1.side = outputSide
                            storageAddresses[address1] = {}
                            storageAddresses[address1].name = transposerAddresses[address].transposer.getInventoryName(outputSide)
                            storageAddresses[address1].address = address
                            storageAddresses[address1].outputSide = outputSide
                            storageAddresses[address1].inputSide = inputSide
                        end
                    end
                end
            end
        end
    end
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

function drawItems()
    items_on_the_screen = db:execute("SELECT FROM ITEMS LIMIT " .. sizeOfPage .. " SKIP " .. (page - 1) * sizeOfPage .. " ORDER BY count", nil)
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
    return dataBase:setFilter(name)
end

function saveItems()
    local file = io.open(shell.getWorkingDirectory() .. "/Chest.lua", "w")
    file:write(serial.serialize(items))
    file:close()
end

function sinkItemsWithStorages()
    db:execute("DELETE FROM ITEMS")
    local items = {}
    for address, storage in pairs(storageAddresses) do
        if (transposerAddresses[storage.address].transposer.getInventorySize(storage.outputSide) ~= nil) then
            local itemsOfStorage = transposerAddresses[storage.address].transposer.getAllStacks(storage.outputSide).getAll()
            for k = 1, #itemsOfStorage do
                local v = itemsOfStorage[k]
                --                    if (v.name ~= 'minecraft:air') then
                local id = getDbId(v.name, v.damage)
                if (not items[id]) then
                    items[id] = {}
                    items[id].name = v.name
                    items[id].damage = v.damage
                    items[id].label = v.label
                    items[id].count = 0
                    items[id].itemXdata = {}
                end
                items[id].count = items[id].count + v.size

                if (not items[id].itemXdata[storage.address]) then items[id].itemXdata[storage.address] = {} end
                if (not items[id].itemXdata[storage.address][storage.outputSide]) then items[id].itemXdata[storage.address][storage.outputSide] = {} end
                if (not items[id].itemXdata[storage.address][storage.outputSide][k]) then items[id].itemXdata[storage.address][storage.outputSide][k] = {} end

                local itemXdata = {}
                itemXdata.size = v.size
                items[id].itemXdata[storage.address][storage.outputSide][k] = itemXdata
                --                    end
            end
        end
    end

    for k, v in pairs(items) do
        db:execute("INSERT INTO ITEMS " .. k, v)
    end
end


function getItemFromSlot(storageX, side, index, count)
    local item = {}
    local storage = transposerAddresses[storageX]
    storage.transposer.transferItem(side, storage.inputSide, count, index)
    if (side ~= 0) then
        local temp_item = storage.transposer.getStackInSlot(side, index)
        if (temp_item) then
            item.storage = storageX
            item.side = side
            item.index = index
            item.size = temp_item.size
        else
            item.storage = storageX
            item.side = side
            item.index = index
            item.size = 0
        end
    end
    if (#storageX > 0) then
        getItemFromSlot(storageX:sub(1, #storageX - 1), tonumber(storageX:sub(#storageX, #storageX)), 1, count)
    end
    return item
end

function setNameToItem(id, name)
    dataBase:setNameForItem(id, name)
end

function getDbId(id, damage)
    return (id .. "_" .. damage):gsub(":", "")
end

function getItemsFromRow(rows, count)
    local returnList = {}
    if (next(rows)) then
        local row = rows[1]
        for i, ix in pairs(row.itemXdata) do
            for j, jx in pairs(row.itemXdata[i]) do
                for k, kx in pairs(row.itemXdata[i][j]) do

                    local item = {}
                    item.storage = i
                    item.side = j
                    item.slot = k
                    local countOfItemsOnSlot = row.itemXdata[i][j][k].size
                    if (count) then
                        if (count > countOfItemsOnSlot) then
                            item.size = countOfItemsOnSlot
                            count = count - countOfItemsOnSlot
                        else
                            item.size = count
                            count = 0
                        end
                    end
                    table.insert(returnList, item)

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

function getItem(id, damage, count)
    local itemsFromDb = db:execute("SELECT FROM ITEMS WHERE ID = " .. getDbId(id, damage), nil)
    local slots = getItemsFromRow(itemsFromDb, count)
    if not slots then
        return
    end
    for i = 1, #slots do
        local slot = slots[i]
        local item = getItemFromSlot(slot.storage, slot.side, slot.slot, slot.size)
        local oldCountOfItems = itemsFromDb[1].itemXdata[slot.storage][slot.side][slot.slot].size
        itemsFromDb[1].itemXdata[slot.storage][slot.side][slot.slot].size = item.size
        itemsFromDb[1].count = itemsFromDb[1].count + item.size - oldCountOfItems
    end
    db:execute("INSERT INTO ITEMS " .. getDbId(id, damage), itemsFromDb[1])
end

function transferItemBack(slot, chest_x, side, index, count, level)
    local sourceSide = 1
    local storage = transposerAddresses[chest_x:sub(0, level)]
    if (level ~= 0) then
        sourceSide = storage.inputSide
    end
    if (level < #chest_x) then
        storage.transposer.transferItem(sourceSide, tonumber(chest_x:sub(level + 1, level + 1)), count, slot, 1)
        return transferItemBack(1, chest_x, side, index, count, level + 1)
    else
        transposerAddresses[chest_x].transposer.transferItem(sourceSide, side, count, slot, index)
        local tempItem = transposerAddresses[chest_x].transposer.getStackInSlot(side, index)
        local item = {}
        item.storage = chest_x
        item.side = side
        item.slot = index
        item.size = tempItem.size
        item.name = tempItem.name
        item.label = tempItem.label
        item.damage = tempItem.damage
        return item
    end
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

function craft(item, count)
end

function pushItems()
    local itemsFromDb = db:execute("SELECT FROM ITEMS WHERE ID = " .. id_of_available_slot, nil)
    local availableSlots = getItemsFromRow(itemsFromDb, nil)
    local items = {}
    local caret = 1
    for i = 1, transposerAddresses[""].transposer.getInventorySize(1) do
        local tempItem = transposerAddresses[""].transposer.getStackInSlot(1, i)
        if (tempItem) then
            if (tempItem.size < tempItem.maxSize) then
                transposerAddresses[""].transposer.store(1, i, data.address, 1)
                local slots = getNotFullSlots(tempItem.name, tempItem.damage, tempItem.maxSize)
                local flag = true
                for j = 1, #slots do
                    if (transposerAddresses[slots[j].storage].transposer.compareStackToDatabase(slots[j].side, slots[j].slot, data.address, 1, true)) then
                        local count = tempItem.maxSize - transposerAddresses[slots[j].storage].transposer.getStackInSlot(slots[j].side, slots[j].slot).size
                        table.insert(items, transferItemBack(i, slots[j].storage, slots[j].side, slots[j].slot, count, 0))
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
            itemToSave.label = items[i].label
            itemToSave.count = itemToSave.count + countToIncrease
            itemsToSave[id] = itemToSave
        end
    end

    for k, v in pairs(itemsToSave) do
        db:execute("INSERT INTO ITEMS " .. k, v)
    end
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
drawInterface()

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
        elseif (isClicked(73, 3, 73, 2 + sizeOfPage, x, y)) then
            local id_with_damage = items_on_the_screen[y - 2].count
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
                        setNameToItem(id_with_damage, str)
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
