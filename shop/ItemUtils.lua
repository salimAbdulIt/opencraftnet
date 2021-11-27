local itemService = {}
local component = require("component")
local shell = require("shell")
local filesystem = require("filesystem")
local meInterface = component.me_interface

local itemService = {}

local CURRENCY = {
    name = nil,
    id = nil,
    dmg = nil
}

local containerSize = 40

itemService.setCurrency = function(currency)
    CURRENCY = currency
end

itemService.giveMoney = function(money)
    money = math.floor(money + 0.5)
    while money > 0 do
        local executed, g = pcall(function()
            return meInterface.exportItem(CURRENCY, 1, money < 64 and money or 64).size
        end)
        money = money - (money < 64 and money or 64)
    end
end

itemService.takeMoney = function(money)
    local sum = 0
    for i = 1, containerSize do
        local item = component.pim.getStackInSlot(i)
        if item and not item.nbt_hash and item.id == CURRENCY.id and item.dmg == CURRENCY.dmg then
            sum = sum + component.pim.pushItem(0, i, money - sum)
        end
    end
    if sum < money then
        itemService.giveMoney(sum)
        return false, "Нужно " .. CURRENCY.name .. " x" .. money
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
