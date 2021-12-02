local component = require('component')
require('database')
local itemUtils = require('ItemUtils')
local utils = require('utils')
ShopService = {}
local pim = component.pim
local event = require('event')
require('dlog')

event.shouldInterrupt = function()
    return false
end

function ShopService:new(terminalName)
    local obj = {}

    function obj:init()
        self.oreExchangeList = utils.readObjectFromFile("home/config/oreExchanger.cfg")
        self.exchangeList = utils.readObjectFromFile("home/config/exchanger.cfg")
        self.sellShopList = utils.readObjectFromFile("home/config/sellShop.cfg")
        self.buyShopList = utils.readObjectFromFile("home/config/buyShop.cfg")

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



    function obj:getExchangeList()
        return self.exchangeList
    end


    function obj:getSellShopList(category)
        local categorySellShopList = {}

        for i, sellConfig in pairs(self.sellShopList) do
            if (sellConfig.category == category) then
                table.insert(categorySellShopList, sellConfig)
            end
        end
        itemUtils.populateCount(categorySellShopList)

        return categorySellShopList
    end

    function obj:getBuyShopList()
        local categoryBuyShopList = self.buyShopList

        itemUtils.populateUserCount(categoryBuyShopList)

        return categoryBuyShopList
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
            printD(terminalName .. ": Игрок " .. nick .. " пополнил баланс на " .. countOfMoney .. " Текущий баланс " .. playerData.balance)
            return playerData.balance, "Баланс пополнен на " .. countOfMoney
        end
        return 0, "Нету монеток в инвентаре!"
    end

    function obj:withdrawMoney(nick, count)
        local playerData = self:getPlayerData(nick)

        if (playerData.balance < count) then
            return 0, "Не хватает денег на счету"
        end
        local countOfMoney = itemUtils.giveMoney(count)
        if (countOfMoney > 0) then
            playerData.balance = playerData.balance - countOfMoney
            self.db:insert(nick, playerData)
            printD(terminalName .. ": Игрок " .. nick .. " снял с баланса " .. countOfMoney .. ". Текущий баланс " .. playerData.balance)
            return countOfMoney, "C баланса списанно " .. countOfMoney
        end
        if (itemUtils.countOfAvailableSlots() > 0) then
            return 0, "Нету монеток в магазине!"
        else
            return 0, "Освободите инвентарь!"
        end
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

    function obj:withdrawItem(nick, id, dmg, count)
        local playerData = self:getPlayerData(nick)
        for i = 1, #playerData.items do
            local item = playerData.items[i]
            if (item.id == id and item.dmg == dmg) then
                local countToWithdraw = math.min(count, item.count)
                local withdrawedCount = itemUtils.giveItem(id, dmg, countToWithdraw)
                item.count = item.count - withdrawedCount
                if (item.count == 0) then
                    table.remove(playerData.items, i)
                end
                self.db:insert(nick, playerData)
                if (withdrawedCount > 0) then
                    printD(terminalName .. ": Игрок " .. nick .. " забрал " .. id .. ":" .. dmg .. " в количестве " .. withdrawedCount)
                end
                return withdrawedCount, "Выданно " .. withdrawedCount .. " вещей"
            end
        end
        return 0, "Вещей нету в наличии!"
    end

    function obj:sellItem(nick, itemCfg, count)
        local playerData = self:getPlayerData(nick)

        if (playerData.balance < count * itemCfg.price) then
            return false, "Не хватает денег на счету"
        end
        local itemsCount = itemUtils.giveItem(itemCfg.id, itemCfg.dmg, count, itemCfg)

        if (itemsCount > 0) then
            playerData.balance = playerData.balance - itemsCount * itemCfg.price
            self.db:insert(nick, playerData)
            printD(terminalName .. ": Игрок " .. nick .. " купил " .. itemCfg.id .. ":" .. itemCfg.dmg .. " в количестве " .. itemsCount .. " по цене " .. itemCfg.price .. " за шт. Текущий баланс " .. playerData.balance)
        end
        return itemsCount, "Куплено " .. itemsCount .. " предметов!"
    end


    function obj:buyItem(nick, itemCfg, count)
        local playerData = self:getPlayerData(nick)

        local itemsCount = itemUtils.takeItem(itemCfg.id, itemCfg.dmg, count)

        if (itemsCount > 0) then
            playerData.balance = playerData.balance + itemsCount * itemCfg.price
            self.db:insert(nick, playerData)
            printD(terminalName .. ": Игрок " .. nick .. " продал " .. itemCfg.id .. ":" .. itemCfg.dmg .. " в количестве " .. itemsCount .. " по цене " .. itemCfg.price .. " за шт. Текущий баланс " .. playerData.balance)
        end
        return itemsCount, "Продано " .. itemsCount .. " предметов!"
    end

    function obj:withdrawAll(nick)
        local playerData = self:getPlayerData(nick)
        local toRemove = {}
        local sum = 0
        for i = 1, #playerData.items do
            local item = playerData.items[i]
            local withdrawedCount = itemUtils.giveItem(item.id, item.dmg, item.count)
            sum = sum + withdrawedCount
            item.count = item.count - withdrawedCount
            if (item.count == 0) then
                table.insert(toRemove, i)
            end
            if (withdrawedCount > 0) then
                printD(terminalName .. ": Игрок " .. nick .. " забрал " .. item.id .. ":" .. item.dmg .. " в количестве " .. withdrawedCount)
            end
        end
        for i = #toRemove, 1, -1 do
            table.remove(playerData.items, toRemove[i])
        end

        self.db:insert(nick, playerData)
        if (sum == 0) then
            if (itemUtils.countOfAvailableSlots() > 0) then
                return sum, "Вещей нету в наличии!"
            else
                return sum, "Освободите инвентарь!"
            end
        end
        return sum, "Выданно " .. sum .. " вещей"
    end

    function obj:exchangeAllOres(nick)
        local items = {}
        for i, itemConfig in pairs(self.oreExchangeList) do
            local item = {}
            item.id = itemConfig.fromId
            item.dmg = itemConfig.fromDmg
            table.insert(items, item)
        end
        local itemsTaken = itemUtils.takeItems(items)

        local playerData = self:getPlayerData(nick)
        local sum = 0
        for i, item in pairs(itemsTaken) do
            sum = sum + item.count
            local itemCfg
            for j, itemConfig in pairs(self.oreExchangeList) do
                if (item.id == itemConfig.fromId and item.dmg == itemConfig.fromDmg) then
                    itemCfg = itemConfig
                    break
                end
            end
            printD(terminalName .. ": Игрок " .. nick .. " обменял на слитки " .. itemCfg.fromId .. ":" .. itemCfg.fromDmg .. " в количестве " .. item.count .. " по курсу " .. itemCfg.fromCount .. "к" .. itemCfg.toCount)
            local itemAlreadyInFile = false
            for i = 1, #playerData.items do
                local itemP = playerData.items[i]
                if (itemP.id == itemCfg.toId and itemP.dmg == itemCfg.toDmg) then
                    itemP.count = itemP.count + item.count * itemCfg.toCount / itemCfg.fromCount
                    itemAlreadyInFile = true
                    break
                end
            end
            if (not itemAlreadyInFile) then
                local newItem = {}
                newItem.id = itemCfg.toId
                newItem.dmg = itemCfg.toDmg
                newItem.label = itemCfg.toLabel
                newItem.count = item.count * itemCfg.toCount / itemCfg.fromCount
                table.insert(playerData.items, newItem)
            end
        end
        self.db:insert(nick, playerData)
        if (sum == 0) then
            return 0, "Нету руд в инвентаре!"
        else
            return sum, " Обменяно " .. sum .. " руд на слитки.", "Заберите из корзины"
        end
    end

    function obj:exchangeOre(nick, itemConfig, count)
        local countOfItems = itemUtils.takeItem(itemConfig.fromId, itemConfig.fromDmg, count)
        if (countOfItems > 0) then
            local playerData = self:getPlayerData(nick)
            local itemAlreadyInFile = false
            for i = 1, #playerData.items do
                local item = playerData.items[i]
                if (item.id == itemConfig.toId and item.dmg == itemConfig.toDmg) then
                    item.count = item.count + countOfItems * itemConfig.toCount / itemConfig.fromCount
                    itemAlreadyInFile = true
                    break
                end
            end
            if (not itemAlreadyInFile) then
                local item = {}
                item.id = itemConfig.toId
                item.dmg = itemConfig.toDmg
                item.label = itemConfig.toLabel
                item.count = countOfItems * itemConfig.toCount / itemConfig.fromCount
                table.insert(playerData.items, item)
            end
            self.db:insert(nick, playerData)
            printD(terminalName .. ": Игрок " .. nick .. " обменял " .. itemConfig.fromId .. ":" .. itemConfig.fromDmg .. " в количестве " .. countOfItems .. " по курсу " .. itemConfig.fromCount .. "к" .. itemConfig.toCount)
            return countOfItems, " Обменяно " .. countOfItems .. " руд на слитки.", "Заберите из корзины"
        end
        return 0, "Нету руд в инвентаре!"
    end

    function obj:exchange(nick, itemConfig, count)
        local countOfItems = itemUtils.takeItem(itemConfig.fromId, itemConfig.fromDmg, count * itemConfig.fromCount)
        local countOfExchanges = math.floor(countOfItems / itemConfig.fromCount)
        local left = math.floor(countOfItems % itemConfig.fromCount)
        local save = false
        local playerData = self:getPlayerData(nick)
        if (left > 0) then
            save = true
            local itemAlreadyInFile = false
            for i = 1, #playerData.items do
                local item = playerData.items[i]
                if (item.id == itemConfig.fromId and item.dmg == itemConfig.fromDmg) then
                    item.count = item.count + left
                    itemAlreadyInFile = true
                    break
                end
            end
            if (not itemAlreadyInFile) then
                local item = {}
                item.id = itemConfig.fromId
                item.dmg = itemConfig.fromDmg
                item.label = itemConfig.fromLabel
                item.count = left
                table.insert(playerData.items, item)
            end
            self.db:insert(nick, playerData)
        end
        if (countOfExchanges > 0) then
            save = true
            local itemAlreadyInFile = false
            for i = 1, #playerData.items do
                local item = playerData.items[i]
                if (item.id == itemConfig.toId and item.dmg == itemConfig.toDmg) then
                    item.count = item.count + countOfExchanges * itemConfig.toCount
                    itemAlreadyInFile = true
                    break
                end
            end
            if (not itemAlreadyInFile) then
                local item = {}
                item.id = itemConfig.toId
                item.dmg = itemConfig.toDmg
                item.label = itemConfig.toLabel
                item.count = countOfExchanges * itemConfig.toCount
                table.insert(playerData.items, item)
            end
            printD(terminalName .. ": Игрок " .. nick .. " обменял " .. itemConfig.fromId .. ":" .. itemConfig.fromDmg .. " на " .. itemConfig.toId .. ":" .. itemConfig.toDmg .. " в количестве " .. countOfItems .. " по курсу " .. itemConfig.fromCount .. "к" .. itemConfig.toCount)
        end
        if(save) then
            self.db:insert(nick, playerData)
            if (countOfExchanges > 0) then
                return countOfItems, " Обменяно " .. countOfItems .. " предметов.", "Заберите из корзины"
            end
        end
        return 0, "Нету вещей в инвентаре!"
    end

    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
