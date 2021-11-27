local itemService = {}
local component = require("component")
local shell = require("shell")
local filesystem = require("filesystem")
local meInterface = component.me_interface

local itemService = {}

local CURRENCY = {
    name = nil,
    damage = nil
}

local containerSize = 40

itemService.setCurrency = function(currency)
    CURRENCY = currency
end

itemService.giveMoney = function(money)
    local itemCount = money/1000
    while itemCount > 0 do
        local executed, g = pcall(function()
            return meInterface.exportItem(CURRENCY, "UP", itemCount < 64 and itemCount or 64).size
        end)
        itemCount = itemCount - (itemCount < 64 and itemCount or 64)
    end
end

itemService.takeMoney = function(money)
    local itemCount = money/1000
    local sum = 0
    for i = 1, containerSize do
        local item = component.pim.getStackInSlot(i)
        if item and not item.nbt_hash and item.id == CURRENCY.name and item.dmg == CURRENCY.damage then
            sum = sum + component.pim.pushItem("DOWN", i, itemCount - sum)
        end
    end
    if sum < itemCount then
        itemService.giveMoney(sum)
        return false, "Нужно " .. CURRENCY.name .. " x" .. itemCount
    end
    return true
end

itemService.rewardItem = function(id, dmg, count)

end

itemService.getCurrencyInStorage = function(currency)
    if not currency.id then
        return -1
    end
    local item = {id=currency.id, dmg=currency.dmg}
    local detail = meInterface.getItemDetail(item)
    return detail and detail.basic().qty or 0
end

return itemService
