local component = require('component')
require('database')
local utils = require('utils')
BalanceService = {}
local pim = component.pim
local event = require('event')
require('dlog')

event.shouldInterrupt = function()
    return false
end

function BalanceService:new()
    local obj = {}

    function obj:init()
        self.db = DurexDatabase:new("BALANCE")
    end

    function obj:getBalancedItems()
        local itemsFromMe =  component.me_interface.getCraftables()
        local balancedItems = self.db:select({ self:dbClause("ID", "balancer", "=") })
        if (not balancedItems or not balancedItems[1]) then
            balancedItems = {}
        else
            balancedItems = balancedItems[1]
        end

        local listToReturn = {}

        for i, itemFromMe in pairs(itemsFromMe) do
            if (i == "n") then
                break
            end
            local itemCfg = itemFromMe.getItemStack()

            local itemToReturn = {}
            itemToReturn.name = itemCfg.name
            itemToReturn.label = itemCfg.label
            itemToReturn.dmg = itemCfg.dmg
            itemToReturn.count = 0

            local isInDb = false
            for j, balancedItem in pairs(balancedItems) do
                if (balancedItem.name == itemCfg.name and balancedItem.dmg == itemCfg.dmg) then
                    itemToReturn.count = balancedItem.count
                    break
                end
            end
            table.insert(listToReturn, itemToReturn)
        end

        return listToReturn
    end

    function obj:dbClause(fieldName, fieldValue, typeOfClause)
        local clause = {}
        clause.column = fieldName
        clause.value = fieldValue
        clause.operation = typeOfClause
        return clause
    end

    function obj:balanceItem(item, count)
        local balancedItems = self.db:select({ self:dbClause("ID", "balancer", "=") })
        if (not balancedItems or not balancedItems[1]) then
            balancedItems = {}
        else
            balancedItems = balancedItems[1]
        end

        for i, itemFromDb in pairs(balancedItems) do
            if (itemFromDb.name == item.name and itemFromDb.dmg == item.dmg) then
                itemFromDb.count = count
                self.db:insert("balancer", balancedItems)
                return
            end
        end
        local newItem = {}
        newItem.name = item.name
        newItem.dmg = item.dmg
        newItem.count = count
        table.insert(balancedItems, newItem)
        self.db:insert("balancer", balancedItems)
    end

    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
