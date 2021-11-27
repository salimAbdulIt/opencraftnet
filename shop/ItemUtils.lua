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

itemService.giveItem = function(id, dmg, count)
    local sum = 0
    while count > sum do
        local executed, result = pcall(function()
            return meInterface.exportItem({ id = id, dmg = dmg }, "UP", (count - sum) < 64 and (count - sum) or 64).size
        end)
        if (not executed) then
            return sum
        end
        sum = sum + result
        if (result == 0) then
            return sum
        end
    end
    return sum
end

itemService.giveMoney = function(money)
    local itemCount = money / 1000
    if (itemCount ~= math.floor(itemCount)) then
        return false
    end

    local sum = 0

    local currency1kk = math.floor(itemCount / 1000)
    local currenct1kkGiven = itemService.giveItem(CURRENCIES[4].item.name, CURRENCIES[4].item.damage, currency1kk)
    itemCount = itemCount - currenct1kkGiven * 1000
    sum = sum + currenct1kkGiven * 1000

    local currency100k = math.floor(itemCount / 100)
    local currenct100kGiven = itemService.giveItem(CURRENCIES[3].item.name, CURRENCIES[3].item.damage, currency100k)
    itemCount = itemCount - currenct100kGiven * 100
    sum = sum + currenct100kGiven * 100

    local currency10k = math.floor(itemCount / 10)
    local currenct10kGiven = itemService.giveItem(CURRENCIES[2].item.name, CURRENCIES[2].item.damage, currency10k)
    itemCount = itemCount - currenct10kGiven * 10
    sum = sum + currenct10kGiven * 10

    local currency1k = math.floor(itemCount)
    local currenct1kGiven = itemService.giveItem(CURRENCIES[1].item.name, CURRENCIES[1].item.damage, currency1k)
    itemCount = itemCount - currenct1kGiven
    sum = sum + currenct1kGiven

    return sum * 1000
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

itemService.takeMoney = function(money)
    local itemCount = money / 1000
    if (itemCount ~= math.floor(itemCount)) then
        return false
    end
    local sum = 0
    local currency1kk = math.floor(itemCount / 1000)
    local currenct1kkTook = itemService.takeItem(CURRENCIES[4].item.name, CURRENCIES[4].item.damage, currency1kk)
    sum = sum + currenct1kkTook * 1000
    itemCount = itemCount - currenct1kkTook * 1000

    local currency100k = math.floor(itemCount / 100)
    local currenct100kTook = itemService.takeItem(CURRENCIES[3].item.name, CURRENCIES[3].item.damage, currency100k)
    sum = sum + currenct100kTook * 100
    itemCount = itemCount - currenct100kTook * 100

    local currency10k = math.floor(itemCount / 10)
    local currenct10kTook = itemService.takeItem(CURRENCIES[2].item.name, CURRENCIES[2].item.damage, currency10k)
    sum = sum + currenct10kTook * 10
    itemCount = itemCount - currenct10kTook * 10

    local currency1k = math.floor(itemCount)
    local currenct1kTook = itemService.takeItem(CURRENCIES[1].item.name, CURRENCIES[1].item.damage, currency1k)
    sum = sum + currenct1kTook
    itemCount = itemCount - currenct1kTook

    return sum * 1000
end

itemService.giveItem = function(id, dmg, count)
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
