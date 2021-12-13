local component = require('component')
local computer = require('computer')
local forms = require("forms") -- подключаем библиотеку
local gpu = component.gpu
local utils = require('utils')
local unicode = require('unicode')
gpu.setResolution(80, 25)
require("shopService")
local shopName = "Shop1"
local shopService = ShopService:new(shopName)
local GarbageForm
local MainForm
local AutorizationForm
local SellShopForm
local ExchangerForm
local OreExchangerForm
local SellShopSpecificForm
local BuyShopForm
local RulesForm

local nickname = ""
local isAutorized = false

local timer

function createNotification(status, text, secondText, callback)
    local notificationForm = forms:addForm()
    notificationForm.border = 2
    notificationForm.W = 31
    notificationForm.H = 10
    notificationForm.left = math.floor((MainForm.W - notificationForm.W) / 2)
    notificationForm.top = math.floor((MainForm.H - notificationForm.H) / 2)
    notificationForm:addLabel(math.floor((notificationForm.W - unicode.len(text)) / 2), 3, text)
    if (secondText) then
        notificationForm:addLabel(math.floor((notificationForm.W - unicode.len(secondText)) / 2), 4, secondText)
    end
    timer = notificationForm:addTimer(3, function()
        callback()
        timer:stop()
    end)
    notificationForm:setActive()
end

function createNumberEditForm(callback, form, buttonText)
    local itemCounterNumberForm = forms:addForm()
    itemCounterNumberForm.border = 2
    itemCounterNumberForm.W = 31
    itemCounterNumberForm.H = 10
    itemCounterNumberForm.left = math.floor((form.W - itemCounterNumberForm.W) / 2)
    itemCounterNumberForm.top = math.floor((form.H - itemCounterNumberForm.H) / 2)
    itemCounterNumberForm:addLabel(8, 3, "Введите количество")
    local itemCountEdit = itemCounterNumberForm:addEdit(8, 4)
    itemCountEdit.W = 18
    itemCountEdit.validator = function(value)
        return tonumber(value) ~= nil
    end
    local backButton = itemCounterNumberForm:addButton(3, 8, " Назад ", function()
        form:setActive()
    end)

    local acceptButton = itemCounterNumberForm:addButton(17, 8, buttonText, function()
        callback(itemCountEdit.text and tonumber(itemCountEdit.text) or 0)
    end)
    return itemCounterNumberForm
end

function createAutorizationForm()
    local AutorizationForm = forms.addForm() -- создаем основную форму
    AutorizationForm.border = 1
    local autorizationLabel = AutorizationForm:addLabel(23, 14, "Что б авторизаватся встаньте на PIM");

    local authorLabel = AutorizationForm:addLabel(32, 25, " Автор: Durex77 ")
    authorLabel.fontColor = 0x00FDFF

    local nameLabel1 = AutorizationForm:addLabel(11, 3, " _                               _    _____ _                 ")
    local nameLabel2 = AutorizationForm:addLabel(11, 4, "| |                             | |  / ____| |  ")
    local nameLabel3 = AutorizationForm:addLabel(11, 5, "| |     ___  __ _  ___ _ __   __| | | (___ | |__   ___  _ __  ")
    local nameLabel4 = AutorizationForm:addLabel(11, 6, "| |    / _ \\/ _` |/ _ \\ '_ \\ / _` |  \\___ \\| '_ \\ / _ \\| '_ \\ ")
    local nameLabel5 = AutorizationForm:addLabel(11, 7, "| |___|  __/ (_| |  __/ | | | (_| |  ____) | | | | (_) | |_) |")
    local nameLabel6 = AutorizationForm:addLabel(11, 8, "|______\\___|\\__, |\\___|_| |_|\\__,_| |_____/|_| |_|\\___/| .__/")
    local nameLabel7 = AutorizationForm:addLabel(11, 9, "             __/ |                                     | |")
    local nameLabel8 = AutorizationForm:addLabel(11, 10, "            |___/                                      |_|    ")

    authorLabel.fontColor = 0x00FDFF

    return AutorizationForm
end


function createListForm(name, label, items, buttons, filter)
    local ShopForm = forms.addForm()
    ShopForm.border = 1
    local shopFrame = ShopForm:addFrame(3, 5, 1)
    shopFrame.W = 76
    shopFrame.H = 18
    local shopNameLabel = ShopForm:addLabel(33, 1, " Legend Shop ")
    shopNameLabel.fontColor = 0x00FDFF
    local authorLabel = ShopForm:addLabel(32, 25, " Автор: Durex77 ")
    authorLabel.fontColor = 0x00FDFF

    local shopNameLabel = ShopForm:addLabel(35, 4, name)
    local shopCountLabel = ShopForm:addLabel(4, 6, label)
    local itemList = ShopForm:addList(5, 7, function()
    end)

    for i = 1, #items do
        if (not filter or (unicode.lower(items[i].displayName):find(unicode.lower(filter)))) then
            itemList:insert(items[i].displayName, items[i])
        end
    end
    itemList.border = 0
    itemList.W = 72
    itemList.H = 15
    itemList.fontColor = 0xFF8F00

    local searchEdit = ShopForm:addEdit(3, 2)
    searchEdit.W = 15


    local searchButton = ShopForm:addButton(19, 3, " Поиск ", function()
        createListForm(name, label, items, buttons, searchEdit.text):setActive()
    end)

    for i, button in pairs(buttons) do
        local shopBackButton = ShopForm:addButton(button.W, button.H, button.name, function()
            if (itemList) then
                button.callback(itemList.items[itemList.index])
            else
                button.callback()
            end
        end)
        if (button.fontColor) then
            shopBackButton.fontColor = button.fontColor
        end
    end
    return ShopForm
end

function createButton(buttonName, W, H, callback, fontColor)
    local button = {}
    button.name = buttonName
    button.W = W
    button.H = H
    button.callback = callback
    button.fontColor = fontColor
    return button
end

function createGarbageForm()
    local items = shopService:getItems(nickname)
    for i = 1, #items do
        local name = items[i].label
        for j = 1, 60 - unicode.len(name) do
            name = name .. ' '
        end
        name = name .. items[i].count .. " шт"

        items[i].displayName = name
    end

    GarbageForm = createListForm(" Корзина ",
        " Наименование                                                Количество",
        items,
        {
            createButton(" Назад ", 3, 23, function(selectedItem)
                MainForm = createMainForm(nickname)
                MainForm:setActive()
            end),
            createButton(" Забрать все ", 68, 23, function(selectedItem)
                local count, message = shopService:withdrawAll(nickname)
                createNotification(count, message, nil, function()
                    createGarbageForm()
                end)
            end),
            createButton(" Забрать ", 55, 23, function(selectedItem)
                if (selectedItem) then
                    local NumberForm = createNumberEditForm(function(count)
                        local count, message = shopService:withdrawItem(nickname, selectedItem.id, selectedItem.dmg, count)

                        createNotification(count, message, nil, function()
                            createGarbageForm()
                        end)
                    end, GarbageForm, "Забрать")
                    NumberForm:setActive()
                end
            end)
        })

    GarbageForm:setActive()
end

function createMainForm(nick)
    local MainForm = forms.addForm()
    MainForm.border = 1
    local shopNameLabel = MainForm:addLabel(33, 1, " Legend Shop ")
    shopNameLabel.fontColor = 0x00FDFF
    local authorLabel = MainForm:addLabel(32, 25, " Автор: Durex77 ")
    authorLabel.fontColor = 0x00FDFF

    local frameBalance = MainForm:addFrame(3, 3, 1)
    frameBalance.W = 76
    frameBalance.H = 7

    MainForm:addLabel(5, 4, "Ваш ник: ")
    MainForm:addLabel(27, 4, nick)

    MainForm:addLabel(5, 6, "Баланс: ")
    MainForm:addLabel(27, 6, shopService:getBalance(nick))

    local sellButton = MainForm:addButton(60, 5, " Выход ", function()
        AutorizationForm:setActive()
    end)
    sellButton.H = 3
    sellButton.W = 15

    local itemCounterNumberSelectDepositBalanceForm = createNumberEditForm(function(count)
        local _, message = shopService:depositMoney(nick, count)

        createNotification(nil, message, nil, function()
            MainForm = createMainForm(nick)
            MainForm:setActive()
        end)
    end, MainForm, "Пополнить")

    local itemCounterNumberSelectWithdrawBalanceForm = createNumberEditForm(function(count)
        local _, message = shopService:withdrawMoney(nick, count)
        createNotification(nil, message, nil, function()
            MainForm = createMainForm(nick)
            MainForm:setActive()
        end)
    end, MainForm, "Снять")

    local depositButton = MainForm:addButton(36, 4, "Пополнить баланс ", function()
        itemCounterNumberSelectDepositBalanceForm:setActive()
    end)
    depositButton.W = 20

    local withdrawButton = MainForm:addButton(36, 6, "Снять с баланса ", function()
        itemCounterNumberSelectWithdrawBalanceForm:setActive()
    end)
    withdrawButton.W = 20

    MainForm:addLabel(5, 8, "Количество предметов: ")
    MainForm:addLabel(27, 8, shopService:getItemCount(nick))

    local withdrawButton = MainForm:addButton(36, 8, "Забрать предметы", function()
        createGarbageForm()
    end)
    withdrawButton.W = 20

    local buyButton = MainForm:addButton(8, 17, " Купить ", function()
        createSellShopForm()
    end)
    buyButton.H = 3
    buyButton.W = 21

    local sellButton = MainForm:addButton(30, 17, " Продать ", function()
        createBuyShopForm()
    end)
    sellButton.H = 3
    sellButton.W = 22

    local exchangeButton = MainForm:addButton(53, 17, " Обмен руд", function()
        createOreExchangerForm()
    end)
    exchangeButton.H = 3
    exchangeButton.W = 21

    local buyButton = MainForm:addButton(8, 21, " Обменик ", function()
        createExchangerForm()
    end)
    buyButton.H = 3
    buyButton.W = 21

    local sellButton = MainForm:addButton(30, 21, " Примечание ", function()
        RulesForm:setActive()
    end)
    sellButton.H = 3
    sellButton.W = 44

    return MainForm
end

function createLabelForm(labels, callback, ParentForm)
    local form = forms:addForm()
    form.border = 2
    form.W = (#labels > 4) and 62 or 31
    form.H = 10 + (#labels > 4 and 3 or (#labels - 1)) * 4
    form.left = math.floor((ParentForm.W - form.W) / 2)
    form.top = math.floor((ParentForm.H - form.H) / 2)
    local edits = {}
    for i = 1, #labels do
        form:addLabel(math.floor((i-1)/4)* 25 + 8, 3 + (i - 1)%4 * 4, labels[i].label)
        edits[i] = form:addEdit(math.floor((i-1)/4)* 25 + 8, 4 + (i - 1)%4 * 4)
        edits[i].W = 18
    end
    local backButton = form:addButton(3, 8 + ((#labels > 4 and 4 or #labels) - 1) * 4, " Назад ", function()
        ParentForm:setActive()
    end)

    local acceptButton = form:addButton(17, 8 + ((#labels > 4 and 4 or #labels) - 1) * 4, "Добавить", function()
        local result = {}
        for i = 1, #edits do
            table.insert(result, edits[i].text and edits[i].text or "")
        end
        callback(result)
    end)
    return form
end


function createSellShopForm()
    SellShopForm = forms.addForm()
    SellShopForm.border = 1
    local shopNameLabel = SellShopForm:addLabel(33, 1, " Legend Shop ")
    shopNameLabel.fontColor = 0x00FDFF
    local authorLabel = SellShopForm:addLabel(32, 25, " Автор: Durex77 ")
    authorLabel.fontColor = 0x00FDFF

    local buyButton2 = SellShopForm:addLabel(23, 3, " █▀▀█ █▀▀█ █ █ █  █ █▀▀█ █ █ █▀▀█ ")
    local buyButton3 = SellShopForm:addLabel(23, 4, " █  █ █  █ █▀▄ █▄▄█ █  █ █▀▄ █▄▄█ ")
    local buyButton4 = SellShopForm:addLabel(23, 5, " ▀  ▀ ▀▀▀▀ ▀ ▀ ▄▄▄█ ▀  ▀ ▀ ▀ ▀  ▀ ")

    local categories = shopService:getSellShopCategories()

    local banners = {
        { x = 5, y = 9 }, { x = 29, y = 9 }, { x = 54, y = 9 },
        { x = 5, y = 13 }, { x = 29, y = 13 }, { x = 54, y = 13 },
        { x = 5, y = 17 }, { x = 29, y = 17 }, { x = 54, y = 17 }
    }
    for i = 1, #categories do
        local categoryButton1 = SellShopForm:addButton(banners[i].x, banners[i].y, categories[i].label, function()
            if (categories[i].enabled or shopService:isAdmin(nickname)) then
                createSellShopSpecificForm(categories[i].id)
            end
        end)
        categoryButton1.W = 23
        categoryButton1.H = 3
        if (not categories[i].enabled) then
            categoryButton1.fontColor = 0xaaaaaa
            categoryButton1.color = 0x000000
        end
    end

    local shopBackButton = SellShopForm:addButton(3, 23, " Назад ", function()
        MainForm = createMainForm(nickname)
        MainForm:setActive()
    end)

    if (shopService:isAdmin(nickname)) then
        local addButton = SellShopForm:addButton(69, 23, " Добавить ", function()
            createLabelForm({ { label = " Введите назву " }, { label = " Введите ID" } }, function(result)
                shopService:addSellCategory(result[1], result[2])
                createSellShopForm()
            end, SellShopForm):setActive()
        end)
        addButton.fontColor = 0xff0000
    end

    SellShopForm:setActive()
end


function createSellShopSpecificForm(category)
    local items = shopService:getSellShopList(category)
    for i = 1, #items do
        local name = items[i].label
        for j = 1, 51 - unicode.len(name) do
            name = name .. ' '
        end
        name = name .. items[i].count

        for j = 1, 62 - unicode.len(name) do
            name = name .. ' '
        end

        name = name .. items[i].price

        items[i].displayName = name
    end

    local categoryConfig = shopService:getSellCategory(category)

    local buttons = {
        createButton(" Назад ", 3, 23, function(selectedItem)
            createSellShopForm()
        end),
        createButton(" Купить ", 68, 23, function(selectedItem)
            local itemCounterNumberSelectForm = createNumberEditForm(function(count)
                local _, message = shopService:sellItem(nickname, selectedItem, count)
                createNotification(nil, message, nil, function()
                    createSellShopSpecificForm(category)
                end)
            end, SellShopForm, "Купить")
            if (selectedItem) then
                itemCounterNumberSelectForm:setActive()
            end
        end)
    }
    if (shopService:isAdmin(nickname)) then
        table.insert(buttons, createButton("Удалить", 57, 23, function(selectedItem)
            if (selectedItem) then
                shopService:deleteSellShopItem(selectedItem)
                createSellShopSpecificForm(category)
            end
        end, 0xff0000))
        table.insert(buttons, createButton("Добавить", 46, 23, function(selectedItem)
            createLabelForm({
                { label = " Введите назву " },
                { label = " Введите ID" },
                { label = " Введите dmg" },
                { label = " Введите nbt" },
                { label = " Введите цену" }
            }, function(result)
                shopService:addSellShopItem(result[1], result[2], result[3], result[4], result[5], category)
                createSellShopSpecificForm(category)
            end, SellShopSpecificForm):setActive()
        end, 0xff0000))
        table.insert(buttons, createButton(" Удалить категорию ", 35, 3, function(selectedItem)
            shopService:removeSellCategory(category)
            createNotification(nil, "Категория удалена", nil, function()
                createSellShopForm()
            end)
        end, 0xff0000))
        table.insert(buttons, createButton(categoryConfig.enabled and " Отключить " or " Включить ", 51, 3, function(selectedItem)
            shopService:enableDissableCategory(category)
            createNotification(nil, "Категория " .. (categoryConfig.enabled and "включена " or "отключена "), nil, function()
                createSellShopSpecificForm(category)
            end)
        end, 0xff0000))
    end

    SellShopSpecificForm = createListForm(" Магазин ",
        " Наименование                                       Количество Цена    ",
        items,
        buttons)

    SellShopSpecificForm:setActive()
end

function createBuyShopForm()
    local items = shopService:getBuyShopList()
    for i = 1, #items do
        local name = items[i].label
        for j = 1, 51 - unicode.len(name) do
            name = name .. ' '
        end
        name = name .. items[i].count

        for j = 1, 62 - unicode.len(name) do
            name = name .. ' '
        end

        name = name .. items[i].price

        items[i].displayName = name
    end

    local buttons = {
        createButton(" Назад ", 3, 23, function(selectedItem)
            MainForm = createMainForm(nickname)
            MainForm:setActive()
        end),
        createButton(" Продать ", 68, 23, function(selectedItem)
            if (selectedItem) then
                local itemCounterNumberSelectForm = createNumberEditForm(function(count)
                    local _, message = shopService:buyItem(nickname, selectedItem, count)
                    createNotification(nil, message, nil, function()
                        createBuyShopForm()
                    end)
                end, MainForm, "Продать")

                itemCounterNumberSelectForm:setActive()
            end
        end)
    }

    if (shopService:isAdmin(nickname)) then
        table.insert(buttons, createButton("Удалить", 57, 23, function(selectedItem)
            if (selectedItem) then
                shopService:deleteBuyShopItem(selectedItem)
                createBuyShopForm()
            end
        end, 0xff0000))
        table.insert(buttons, createButton("Добавить", 46, 23, function(selectedItem)
            createLabelForm({
                { label = " Введите назву " },
                { label = " Введите ID" },
                { label = " Введите dmg" },
                { label = " Введите цену" }
            }, function(result)
                shopService:addBuyShopItem(result[1], result[2], result[3], result[4])
                createBuyShopForm()
            end, BuyShopForm):setActive()
        end, 0xff0000))
    end

    BuyShopForm = createListForm(" Скупка ",
        " Наименование                                       Количество Цена    ",
        items,
        buttons)

    BuyShopForm:setActive()
end

function createOreExchangerForm()
    local items = shopService:getOreExchangeList()
    for i = 1, #items do
        local name = items[i].fromLabel
        for j = 1, 58 - unicode.len(name) do
            name = name .. ' '
        end
        name = name .. items[i].fromCount .. 'к' .. items[i].toCount

        items[i].displayName = name
    end

    local buttons = {
        createButton(" Назад ", 3, 23, function(selectedItem)
            MainForm = createMainForm(nickname)
            MainForm:setActive()
        end),
        createButton(" Обменять все ", 67, 23, function(selectedItem)
            local _, message, message2 = shopService:exchangeAllOres(nickname)
            createNotification(nil, message, message2, function()
                createOreExchangerForm()
            end)
        end),
        createButton(" Обменять ", 54, 23, function(selectedItem)
            if (selectedItem) then
                local itemCounterNumberSelectForm = createNumberEditForm(function(count)
                    local _, message, message2 = shopService:exchangeOre(nickname, selectedItem, count)
                    createNotification(nil, message, message2, function()
                        createOreExchangerForm()
                    end)
                end, OreExchangerForm, "Обменять")
                itemCounterNumberSelectForm:setActive()
            end
        end)
    }

    if (shopService:isAdmin(nickname)) then
        table.insert(buttons, createButton("Удалить", 43, 23, function(selectedItem)
            if (selectedItem) then
                shopService:deleteOreExchangeItem(selectedItem)
                createOreExchangerForm()
            end
        end, 0xff0000))
        table.insert(buttons, createButton("Добавить", 32, 23, function(selectedItem)
            createLabelForm({
                { label = " Введите назву(что)" },
                { label = " Введите ID(что)" },
                { label = " Введите dmg(что)" },
                { label = " Введите количестово(что)" },
                { label = " Введите назву(на)" },
                { label = " Введите ID(на)" },
                { label = " Введите dmg(на)" },
                { label = " Введите количестово(на)" }
            }, function(result)
                shopService:addOreExchangeItem(result[1], result[2], result[3], result[4], result[5], result[6], result[7], result[8])
                createOreExchangerForm()
            end, OreExchangerForm):setActive()
        end, 0xff0000))
    end

    OreExchangerForm = createListForm(" Обмен руд ",
        " Наименование                                              Курс обмена ",
        items,
        buttons)

    OreExchangerForm:setActive()
end

function createExchangerForm()
    local items = shopService:getExchangeList()
    for i = 1, #items do
        local name = items[i].fromLabel
        for j = 1, 25 - unicode.len(name) do
            name = name .. ' '
        end
        name = name .. items[i].fromCount .. 'к' .. items[i].toCount
        for j = 1, 50 - unicode.len(name) do
            name = name .. ' '
        end
        name = name .. items[i].toLabel
        items[i].displayName = name
    end

    local buttons = {
        createButton(" Назад ", 3, 23, function(selectedItem)
            MainForm = createMainForm(nickname)
            MainForm:setActive()
        end),
        createButton(" Обменять ", 68, 23, function(selectedItem)
            if (selectedItem) then
                local itemCounterNumberSelectForm = createNumberEditForm(function(count)
                    local _, message, message2 = shopService:exchange(nickname, selectedItem, count)
                    createNotification(nil, message, message2, function()
                        createExchangerForm()
                    end)
                end, ExchangerForm, "Обменять")
                itemCounterNumberSelectForm:setActive()
            end
        end)
    }

    if (shopService:isAdmin(nickname)) then
        table.insert(buttons, createButton("Удалить", 43, 23, function(selectedItem)
            if (selectedItem) then
                shopService:deleteExchangeItem(selectedItem)
                createExchangerForm()
            end
        end, 0xff0000))
        table.insert(buttons, createButton("Добавить", 32, 23, function(selectedItem)
            createLabelForm({
                { label = " Введите назву(что)" },
                { label = " Введите ID(что)" },
                { label = " Введите dmg(что)" },
                { label = " Введите количестово(что)" },
                { label = " Введите назву(на)" },
                { label = " Введите ID(на)" },
                { label = " Введите dmg(на)" },
                { label = " Введите количестово(на)" }
            }, function(result)
                shopService:addExchangeItem(result[1], result[2], result[3], result[4], result[5], result[6], result[7], result[8])
                createExchangerForm()
            end, ExchangerForm):setActive()
        end, 0xff0000))
    end

    ExchangerForm = createListForm(" Обменик ",
        " Наименование             Курс обмена              Наименование       ",
        items,
        buttons)

    ExchangerForm:setActive()
end

function createRulesForm()
    local ShopForm = forms.addForm()
    ShopForm.border = 1
    local shopFrame = ShopForm:addFrame(3, 5, 1)
    shopFrame.W = 76
    shopFrame.H = 18
    local shopNameLabel = ShopForm:addLabel(33, 1, " Legend Shop ")
    shopNameLabel.fontColor = 0x00FDFF
    local authorLabel = ShopForm:addLabel(32, 25, " Автор: Durex77 ")
    authorLabel.fontColor = 0x00FDFF

    local shopNameLabel = ShopForm:addLabel(35, 4, " Примечания ")

    local ruleList = ShopForm:addList(5, 6, function()
    end)

    ruleList:insert("1. Баланс на компьютерах разный, пользуйтесь одним магазином для удобства пользования! ")
    ruleList:insert("2. При возникновении какого либо вопроса, обращайтесь к:")
    ruleList:insert("   Durex77")
    ruleList:insert("3. Вывод/ввод денег осуществляется кратно 1")

    ruleList.border = 0
    ruleList.W = 73
    ruleList.H = 15
    ruleList.fontColor = 0xFF8F00

    local shopBackButton = ShopForm:addButton(3, 23, " Назад ", function()
        MainForm = createMainForm(nickname)
        MainForm:setActive()
    end)

    shopBackButton.H = 1
    shopBackButton.W = 9
    return ShopForm
end

function autorize(nick)
    MainForm = createMainForm(nick)
    nickname = nick
    isAutorized = true
    MainForm:setActive()
end

AutorizationForm = createAutorizationForm()
RulesForm = createRulesForm()


local Event1 = AutorizationForm:addEvent("player_on", function(e, p)
    gpu.setResolution(80, 25)
    if (p) then
        computer.addUser(p)
        autorize(p)
    end
end)

local Event1 = AutorizationForm:addEvent("player_off", function(e, p)
    if (not shopService:isAdmin(nickname)) then
        computer.removeUser(nickname)
    end
    if (timer) then
        timer:stop()
    end
    AutorizationForm:setActive()
end)

forms.run(AutorizationForm) --запускаем gui


