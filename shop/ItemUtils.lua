local itemService = {}
local component = require("component")
local shell = require("shell")
local filesystem = require("filesystem")
local meInterface = component.me_interface

local itemService = {}

local CURRENCIES = {}

local containerSize = 40

itemService.setCurrency = function(currencies)
    CURRENCIES = currencies
end

itemService.giveItem = function(id, dmg, count, nbt)
    local sum = 0
    while count > sum do
        local executed, result = pcall(function()
            if (nbt) then
                return meInterface.exportItem({ id = id, dmg = dmg, nbt_hash = nbt }, "UP", (count - sum) < 64 and (count - sum) or 64).size
            else
                local executed1, count1 = pcall(function()
                    return meInterface.exportItem({ id = id, dmg = dmg }, "UP", (count - sum) < 64 and (count - sum) or 64).size
                end)

                if (executed1 and count1 > 0) then
                    return count1
                end
                local itemsFromMe = meInterface.getAvailableItems()

                for k, itemFromMe in pairs(itemsFromMe) do
                    if (id == itemFromMe.fingerprint.id and dmg == itemFromMe.fingerprint.dmg and itemFromMe.size > 0) then
                        local executed2, count2 = pcall(function()
                            return meInterface.exportItem(itemFromMe.fingerprint, "UP", (count - sum) < 64 and (count - sum) or 64).size
                        end)
                        if executed2 then
                            return count2
                        end
                    end
                end
            end
        end)
        if (not executed) then
            return sum
        end
        if (result) then
            sum = sum + result
        else
            return sum
        end
        if (result == 0) then
            return sum
        end
    end
    return sum
end

itemService.giveMoney = function(money)
    local currenctGiven = itemService.giveItem(CURRENCIES.item.name, CURRENCIES.item.damage, money)

    return currenctGiven
end

itemService.takeItem = function(id, dmg, count)
    if (count == 0) then
        return 0
    end
    local sum = 0
    for i = 1, containerSize do
        local item = component.pim.getStackInSlot(i)
        if item and not item.nbt_hash and item.id == id and item.dmg == dmg then
            sum = sum + component.pim.pushItem("DOWN", i, count - sum)
        end
        if (count == sum) then
            return sum
        end
    end
    return sum
end

itemService.populateCount = function(items)
    local itemsFromMe = meInterface.getAvailableItems()

    for i, item in pairs(items) do
        item.count = 0

        if (item.nbt) then
            for k, itemFromMe in pairs(itemsFromMe) do
                if (item.id == itemFromMe.fingerprint.id and item.nbt == itemFromMe.fingerprint.nbt_hash) then
                    item.count = item.count + itemFromMe.size
                end
            end
        else
            for k, itemFromMe in pairs(itemsFromMe) do
                if (item.id == itemFromMe.fingerprint.id and item.dmg == itemFromMe.fingerprint.dmg) then
                    item.count = item.count + itemFromMe.size
                end
            end
        end
    end
end

itemService.populateUserCount = function(items)
    local itemsFromPlayer = component.pim.getAllStacks()
    for i, item in pairs(items) do
        item.count = 0
        for k, itemFromPlayer in pairs(itemsFromPlayer) do
            if (itemFromPlayer and item.id == itemFromPlayer.all().id and item.dmg == itemFromPlayer.all().dmg) then
                item.count = item.count + itemFromPlayer.all().qty
            end
        end
    end
end

itemService.countOfAvailableSlots = function()
    local count = 0
    local allStacks = component.pim.getAllStacks()
    for i = 1, 40 do
        if (not allStacks[i]) then
            count = count + 1
        end
    end
    return count
end

itemService.takeItems = function(items)
    local sumList = {}
    for i = 1, containerSize do
        local item = component.pim.getStackInSlot(i)
        for j, itemCfg in pairs(items) do
            if item and not item.nbt_hash and item.id == itemCfg.id and item.dmg == itemCfg.dmg then
                local sum = component.pim.pushItem("DOWN", i, item.count)
                if (not sum) then
                    sum = 0
                end
                for k = 1, #sumList do
                    if (sumList[k].id == itemCfg.id and sumList[k].dmg == itemCfg.dmg) then
                        sumList[k].count = sumList[k].count + sum
                        sum = 0
                    end
                end
                if (sum > 0) then
                    local sumElement = {}
                    sumElement.id = itemCfg.id
                    sumElement.dmg = itemCfg.dmg
                    sumElement.count = sum
                    table.insert(sumList, sumElement)
                end
                break
            end
        end
    end
    return sumList
end

itemService.takeMoney = function(money)
    return itemService.takeItem(CURRENCIES.item.name, CURRENCIES.item.damage, money)
end

itemService.getCurrencyInStorage = function(currency)
    if not currency.id then
        return -1
    end
    local item = { id = currency.id, dmg = currency.dmg }
    local detail = meInterface.getItemDetail(item)
    return detail and detail.basic().qty or 0
end

return itemService
