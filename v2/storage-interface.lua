local component = require("component")
local computer = require("computer")
local event = require("event")
local term = require("term")
local shell = require("shell")
local fs = require("filesystem")
local unicode = require("unicode")
local serial = require("serialization")
local gpu = component.gpu

require("storage-system")
local storageSystem = StorageSystem:new()

local items = {}
gpu.setResolution(80, 30)

local page = 1
local sizeOfPage = 26
local items_on_the_screen = {}
local findNameFilter = ''

function drawItems()
    items_on_the_screen = storageSystem:getAllItemsByLabel(findNameFilter, (page - 1) * sizeOfPage, sizeOfPage, "count")
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

function setFilter(name)
    findNameFilter = name
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
            storageSystem:cleanOutputStorage()
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
                            storageSystem:getItem(id, damage, tonumber(str))
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
                            storageSystem:craft(id, damage, tonumber(str))
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
                        storageSystem:setNameToItem(id, damage, str)
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
            storageSystem:addCraft()
        elseif (isClicked(3, 15, 21, 17, x, y)) then
            storageSystem:sinkItemsWithStorages()
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
