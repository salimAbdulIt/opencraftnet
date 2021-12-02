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
        self:update()
    end

    function obj:update()
        local itemsFromDatabase = {}
        for i = 1, 81 do
            local item = component.database.get(i)
            if (item) then
                table.insert(itemsFromDatabase, item)
            end
        end

        self.itemCache = itemsFromDatabase
    end

    function obj:getCache()
        return self.itemCache
    end

    function obj:balance()
        if ((not self.craftingItem) or self.craftingItem.isDone() or self.craftingItem.isCanceled()) then
            local balancedItems = self.db:select({ self:dbClause("ID", "balancer", "=") })
            if (not balancedItems or not balancedItems[1]) then
                balancedItems = {}
            else
                balancedItems = balancedItems[1]
            end


            local item = balancedItems[self.currentIndex]
            if (not item) then
                self.currentIndex = 1
                return
            end
            self.currentIndex = self.currentIndex + 1

            if (item.count > 0) then
                local count = item.count < 5 and item.count or math.floor(item.count * 0.8)
                local itemFromMe = component.me_interface.getItemDetail({ id = item.name, dmg = item.dmg }).basic()

                if (itemFromMe.qty < count) then
                    local cache = self.itemCache
                    for l, itemCfg in pairs(cache) do

                        if (itemCfg.name == item.name and itemCfg.damage == item.dmg) then
                            self.craftingItem = component.me_interface.getCraftables(itemCfg)[1].request(item.count - itemFromMe.qty)
                            return
                        end
                    end
                end
            end
        end
    end

    function obj:getBalancedItems()
        local balancedItems = self.db:select({ self:dbClause("ID", "balancer", "=") })
        if (not balancedItems or not balancedItems[1]) then
            balancedItems = {}
        else
            balancedItems = balancedItems[1]
        end

        local listToReturn = {}

        for i, itemCfg in pairs(self.itemCache) do
            local itemToReturn = {}
            itemToReturn.name = itemCfg.name
            itemToReturn.label = itemCfg.label
            itemToReturn.dmg = itemCfg.damage
            itemToReturn.count = 0

            local isInDb = false
            for j, balancedItem in pairs(balancedItems) do
                if (balancedItem.name == itemCfg.name and balancedItem.dmg == itemCfg.damage) then
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
