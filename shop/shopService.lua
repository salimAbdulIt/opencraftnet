local component = require('component')
require('database')
local itemUtils = require('ItemUtils')
ShopService = {}
local pim = component.pim
function ShopService:new()
    local obj = {}

    function obj:init()
        self.db = DurexDatabase:new("USERS")
        self.currencies = {}
        self.currencies[1] = {}
        self.currencies[1].item = component.database.get(1)
        self.currencies[1].dbSlot = 1
        self.currencies[1].money = 1000

        self.currencies[2] = {}
        self.currencies[2].item = component.database.get(2)
        self.currencies[2].dbSlot = 2
        self.currencies[2].money = 10000

        self.currencies[3] = {}
        self.currencies[3].item = component.database.get(3)
        self.currencies[3].dbSlot = 3
        self.currencies[3].money = 100000

        self.currencies[4] = {}
        self.currencies[4].item = component.database.get(4)
        self.currencies[4].dbSlot = 4
        self.currencies[4].money = 1000000

        itemUtils.setCurrency(self.currencies)
    end

    function obj:dbClause(fieldName, fieldValue, typeOfClause)
        local clause = {}
        clause.column = fieldName
        clause.value = fieldValue
        clause.operation = typeOfClause
        return clause
    end

    function obj:getBalance(nick)
        local itemsFromDb = self.db:select({ self:dbClause("ID", nick, "=") })
        if (itemsFromDb[1]) then
            return itemsFromDb[1].balance
        end
        return 0
    end

    function obj:getItemCount(nick)
        local itemsFromDb = self.db:select({ self:dbClause("ID", nick, "=") })
        if (itemsFromDb[1]) then
            return itemsFromDb[1].itemCount
        end
        return 0
    end

    function obj:depositMoney(nick, count)
        local countOfMoney = itemUtils.takeMoney(count)
        if (countOfMoney > 0) then
            local playerDataList = self.db:select({ self:dbClause("ID", nick, "=") })
            local playerData
            if (not playerDataList or not playerDataList[1]) then
                playerData = {}
                playerData.balance = 0
                playerData.itemCount = 0
            else
                playerData = playerDataList[1]
            end
            playerData.balance = playerData.balance + countOfMoney
            self.db:insert(nick, playerData)
            return true, playerData.balance
        end
        return false
    end

    function obj:withdrawMoney(nick, count)
        local playerDataList = self.db:select({ self:dbClause("ID", nick, "=") })
        local playerData
        if (not playerDataList or not playerDataList[1]) then
            playerData = {}
            playerData.balance = 0
            playerData.itemCount = 0
        else
            playerData = playerDataList[1]
        end

        if (playerData.balance < count) then
            return false, "Не хватает денег на счету"
        end
        local countOfMoney = itemUtils.giveMoney(count)
        if (countOfMoney > 0) then
            playerData.balance = playerData.balance - countOfMoney
            self.db:insert(nick, playerData)
            return true, playerData.balance
        end
        return false
    end


    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
