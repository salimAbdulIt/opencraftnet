local component = require('component')
require('database')
local itemUtils = require('ItemUtils')
ShopService = {}
local pim = component.pim
function ShopService:new()
    local obj = {}

    function obj:init()
        self.oreExchangeList = utils.readObjectFromFile("home/config/oreExchanger.cfg")

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

    function obj:getOreExchangeList()
        return self.oreExchangeList
    end

    function obj:getBalance(nick)
        local playerData = self:getPlayerData(nick)
        if (playerData) then
            return playerData.balance
        end
        return 0
    end

    function obj:getItemCount(nick)
        local playerData = self:getPlayerData(nick)
        if (playerData) then
            return #playerData.items
        end
        return 0
    end

    function obj:getItems(nick)
        local playerData = self:getPlayerData(nick)
        if (playerData) then
            return playerData.items
        end
        return {}
    end

    function obj:depositMoney(nick, count)
        local countOfMoney = itemUtils.takeMoney(count)
        if (countOfMoney > 0) then
            local playerData = self:getPlayerData(nick)

            playerData.balance = playerData.balance + countOfMoney
            self.db:insert(nick, playerData)
            return true, playerData.balance
        end
        return false
    end

    function obj:withdrawMoney(nick, count)
        local playerData = self:getPlayerData(nick)

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

    function obj:getPlayerData(nick)
        local playerDataList = self.db:select({ self:dbClause("ID", nick, "=") })
        local playerData
        if (not playerDataList or not playerDataList[1]) then
            playerData = {}
            playerData.balance = 0
            playerData.items = {}
        else
            playerData = playerDataList[1]
        end
        return playerData
    end

    function obj:exchangeOre(nick, itemConfig, count)
        local countOfItems = itemUtils.takeItem(itemConfig.fromId, itemConfig.fromDmg, count)
        if (countOfItems > 0) then
            local playerData = self:getPlayerData(nick)
            local itemAlreadyInFile = false
            for i=1, #playerData.items do
                local item = playerData.items[i]
                if (item.id == itemConfig.toId and item.dmg == itemConfig.toDmg) then
                    item.count = item.count + countOfItems
                    itemAlreadyInFile = true
                end
            end
            if (not itemAlreadyInFile) then
                local item = {}
                item.id = itemConfig.toId
                item.dmg = itemConfig.toDmg
                item.count = countOfItems
                table.insert(playerData.items, item)
            end
            self.db:insert(nick, playerData)
            return true, playerData.balance
        end
        return false
    end


    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
