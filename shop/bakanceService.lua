local component = require('component')
require('database')
local utils = require('utils')
BalanceService = {}
local event = require('event')
local chat = component.chat_box
chat.setName("Pidor")

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
        self.balancedItems = self.db:select({ self:dbClause("ID", "balancer", "=") })

        if (not self.balancedItems or not self.balancedItems[1]) then
            self.balancedItems = {}
        else
            self.balancedItems = self.balancedItems[1]
        end

        for i = 1, 81 do
            local item = component.database.get(i)
            if (item) then
                local isFound = false
                for j=1,#self.balancedItems do
                    if (self.balancedItems[j].name == item.name and self.balancedItems[j].damage == item.damage) then
                        isFound = true
                        break
                    end
                end
                if (not isFound) then
                    component.database.clear(i)
                    local newItem = {}
                    newItem.name = item.name
                    newItem.damage = item.damage
                    newItem.label = item.label
                    newItem.count = 0
                    table.insert(self.balancedItems, newItem)
                end
            end
        end
        self.db:insert("balancer", self.balancedItems)
    end

    function obj:getCache()
        return self.balancedItems
    end

    function obj:balance()
        local cpus = component.me_interface.getCpus()
        if (not cpus) then
            self.craftingItem = nil
        else
            local isAllCpusOff = true
            for i=1,#cpus do
                if (cpus[i].busy) then
                    isAllCpusOff = false
                end
            end
            if (isAllCpusOff) then
                self.craftingItem = nil
            end
        end

        if ((not self.craftingItem) or self.craftingItem.isDone() or self.craftingItem.isCanceled()) then

            local item = self.balancedItems[self.currentIndex]
            if (not item) then
                self.currentIndex = 1
                return
            end
            self.currentIndex = self.currentIndex + 1

            if (item.count > 0) then
                local count = item.count < 5 and item.count or math.floor(item.count * 0.8)
                local itemFromMe = component.me_interface.getItemDetail({ id = item.name, dmg = item.damage }).basic()

                if (itemFromMe.qty < count) then
                    local filter = {}
                    filter.name = itemFromMe.id
                    filter.damage = itemFromMe.dmg
                    self.craftingItem = component.me_interface.getCraftables(filter)[1].request(item.count - itemFromMe.qty)
                    if (not self.craftingItem.isCanceled()) then
                        chat.say(item.label .. " " .. (item.count - itemFromMe.qty) .. 'шт.')
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

        return balancedItems
    end

    function obj:dbClause(fieldName, fieldValue, typeOfClause)
        local clause = {}
        clause.column = fieldName
        clause.value = fieldValue
        clause.operation = typeOfClause
        return clause
    end

    function obj:balanceItem(item, count)
        for i, itemFromDb in pairs(self.balancedItems) do
            if (itemFromDb.name == item.name and itemFromDb.damage == item.damage) then
                if (count == -1) then
                    table.remove(self.balancedItems, i)
                    self.db:insert("balancer", self.balancedItems)
                    return
                end
                itemFromDb.count = count
                self.db:insert("balancer", self.balancedItems)
                return
            end
        end
        local newItem = {}
        newItem.name = item.name
        newItem.damage = item.damage
        newItem.count = count
        table.insert(self.balancedItems, newItem)
        self.db:insert("balancer", self.balancedItems)
    end

    function obj:renameItem(item, name)
        for i, itemFromDb in pairs(self.balancedItems) do
            if (itemFromDb.name == item.name and itemFromDb.damage == item.damage) then
                itemFromDb.label = name
                self.db:insert("balancer", self.balancedItems)
                return
            end
        end
    end

    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
