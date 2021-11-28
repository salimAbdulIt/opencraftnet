local component = require('component')
local forms = require("forms") -- подключаем библиотеку
local gpu = component.gpu
local utils = require('utils')
gpu.setResolution(80, 25)
require("shopService")
local shopService = ShopService:new()

local GarbageForm
local MainForm
local AutorizationForm
local BuyShopForm
local OreExchangerForm

local nickname = ""
local isAutorized = false

local translations = {
    ["minecraft:iron_ingot:0"] = "Железный слиток",
    ["minecraft:gold_ingot:0"] = "Золотой слиток",
    ["IC2:itemIngot:1"] = "Оловянный слиток",
    ["IC2:itemIngot:0"] = "Медный слиток"
}

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

function createGarbageForm()
    local ShopForm = forms.addForm()
    ShopForm.border = 1
    local shopFrame = ShopForm:addFrame(3, 5, 1)
    shopFrame.W = 76
    shopFrame.H = 18
    local shopNameLabel = ShopForm:addLabel(33, 1, " Legend Shop ")
    shopNameLabel.fontColor = 0x00FDFF
    local authorLabel = ShopForm:addLabel(32, 25, " Автор: Durex77 ")
    authorLabel.fontColor = 0x00FDFF

    local shopNameLabel = ShopForm:addLabel(35, 4, " Корзина ")
    local shopCountLabel = ShopForm:addLabel(4, 6, " Наименование                                                Количество")
    local itemList = ShopForm:addList(5, 7, function()
    end)

    local items = shopService:getItems(nickname)
    for i = 1, #items do
        local name = translations[items[i].id .. ":" .. items[i].dmg]
        for i = 1, 60 - unicode.len(name) do
            name = name .. ' '
        end
        name = name .. items[i].count .. " шт"

        itemList:insert(name, items[i])
    end
    itemList.border = 0
    itemList.W = 70
    itemList.H = 15
    itemList.fontColor = 0xFF8F00

    local itemCounterNumberSelectForm = createNumberEditForm(function(count)
        local itemToWithdraw = itemList.items[itemList.index]
        shopService:withdrawItem(nickname, itemToWithdraw.id, itemToWithdraw.dmg, count)

        GarbageForm = createGarbageForm()
        GarbageForm:setActive()
    end, ShopForm, "Забрать")

    local shopBackButton = ShopForm:addButton(3, 23, " Назад ", function()
        MainForm = createMainForm(nickname)
        MainForm:setActive()
    end)
    local shopWithdrawAllButton = ShopForm:addButton(68, 23, " Забрать все ", function()
        shopService:withdrawAll(nickname)

        GarbageForm = createGarbageForm()
        GarbageForm:setActive()
    end)
    local shopWithdrawButton = ShopForm:addButton(55, 23, " Забрать ", function() itemCounterNumberSelectForm:setActive() end)
    shopBackButton.H = 1
    shopBackButton.W = 9
    return ShopForm
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
        shopService:depositMoney(nick, count)
        MainForm = createMainForm(nick)
        MainForm:setActive()
    end, MainForm, "Пополнить")

    local itemCounterNumberSelectWithdrawBalanceForm = createNumberEditForm(function(count)
        shopService:withdrawMoney(nick, count)
        MainForm = createMainForm(nick)
        MainForm:setActive()
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
        GarbageForm = createGarbageForm()
        GarbageForm:setActive()
    end)
    withdrawButton.W = 20

    local buyButton = MainForm:addButton(8, 17, " Купить ", function()
        BuyShopForm:setActive()
    end)
    buyButton.H = 3
    buyButton.W = 21

    local sellButton = MainForm:addButton(30, 17, " Продать ")
    sellButton.H = 3
    sellButton.W = 22
    sellButton.fontColor = 0xaaaaaa
    sellButton.color = 0x0202020

    local exchangeButton = MainForm:addButton(53, 17, " Обмен руд", function()
        OreExchangerForm:setActive()
    end)
    exchangeButton.H = 3
    exchangeButton.W = 21

    local sellButton = MainForm:addButton(8, 21, " Правила ")
    sellButton.H = 3
    sellButton.W = 66

    return MainForm
end

function createBuyShopForm()
    local BuyShopForm = forms.addForm()
    BuyShopForm.border = 1
    local shopNameLabel = BuyShopForm:addLabel(33, 1, " Legend Shop ")
    shopNameLabel.fontColor = 0x00FDFF
    local authorLabel = BuyShopForm:addLabel(32, 25, " Автор: Durex77 ")
    authorLabel.fontColor = 0x00FDFF

    local buyButton2 = BuyShopForm:addLabel(23, 3, " █▀▀█ █▀▀█ █ █ █  █ █▀▀█ █ █ █▀▀█ ")
    local buyButton3 = BuyShopForm:addLabel(23, 4, " █  █ █  █ █▀▄ █▄▄█ █  █ █▀▄ █▄▄█ ")
    local buyButton4 = BuyShopForm:addLabel(23, 5, " ▀  ▀ ▀▀▀▀ ▀ ▀ ▄▄▄█ ▀  ▀ ▀ ▀ ▀  ▀ ")

    local categoryButton1 = BuyShopForm:addButton(5, 9, " Minecraft ")
    categoryButton1.W = 23
    categoryButton1.H = 3
    local categoryButton1 = BuyShopForm:addButton(29, 9, " Industrial Craft 2 ")
    categoryButton1.W = 24
    categoryButton1.H = 3
    local categoryButton1 = BuyShopForm:addButton(54, 9, " Applied Energistics 2 ")
    categoryButton1.W = 23
    categoryButton1.H = 3

    local categoryButton1 = BuyShopForm:addButton(5, 13, " Forestry ")
    categoryButton1.W = 23
    categoryButton1.H = 3
    local categoryButton1 = BuyShopForm:addButton(29, 13, " Зачарованные книги ")
    categoryButton1.W = 24
    categoryButton1.H = 3
    local categoryButton1 = BuyShopForm:addButton(54, 13, " Draconic Evolution ")
    categoryButton1.W = 23
    categoryButton1.H = 3

    local categoryButton1 = BuyShopForm:addButton(5, 17, " Thermal Expansion ")
    categoryButton1.W = 23
    categoryButton1.H = 3
    local categoryButton1 = BuyShopForm:addButton(29, 17, " Скоро ")
    categoryButton1.W = 24
    categoryButton1.H = 3
    categoryButton1.fontColor = 0xaaaaaa
    categoryButton1.color = 0x000000
    local categoryButton1 = BuyShopForm:addButton(54, 17, " Скоро ")
    categoryButton1.W = 23
    categoryButton1.H = 3
    categoryButton1.fontColor = 0xaaaaaa
    categoryButton1.color = 0x000000

    local shopBackButton = BuyShopForm:addButton(3, 23, " Назад ", function()
        MainForm:setActive()
    end)

    return BuyShopForm
end


function createOreExchangerForm()
    local ShopForm = forms.addForm()
    ShopForm.border = 1
    local shopFrame = ShopForm:addFrame(3, 5, 1)
    shopFrame.W = 76
    shopFrame.H = 18
    local shopNameLabel = ShopForm:addLabel(33, 1, " Legend Shop ")
    shopNameLabel.fontColor = 0x00FDFF
    local authorLabel = ShopForm:addLabel(32, 25, " Автор: Durex77 ")
    authorLabel.fontColor = 0x00FDFF

    local shopNameLabel = ShopForm:addLabel(35, 4, " Обмен руд ")
    local shopCountLabel = ShopForm:addLabel(4, 6, " Наименование                                              Курс обмена ")

    local itemList = ShopForm:addList(5, 7, function()
    end)

    local oreExchangeList = shopService:getOreExchangeList()

    for i = 1, #oreExchangeList do
        local name = oreExchangeList[i].label
        for i = 1, 68 - unicode.len(name) do
            name = name .. ' '
        end
        name = name .. oreExchangeList[i].fromCount .. 'к' .. oreExchangeList[i].toCount

        itemList:insert(name, oreExchangeList[i])
    end
    itemList.border = 0
    itemList.W = 70
    itemList.H = 15
    itemList.fontColor = 0xFF8F00

    local itemCounterNumberSelectForm = createNumberEditForm(function(count)
        shopService:exchangeOre(nickname, itemList.items[itemList.index], count)
        OreExchangerForm = createOreExchangerForm(nickname)
        OreExchangerForm:setActive()
    end, ShopForm, "Обменять")

    local shopBackButton = ShopForm:addButton(3, 23, " Назад ", function()
        MainForm = createMainForm(nickname)
        MainForm:setActive()
    end)
    local shopWithdrawAllButton = ShopForm:addButton(67, 23, " Обменять все ", function()
        shopService:exchangeAllOres(nickname)
        OreExchangerForm = createOreExchangerForm(nickname)
        OreExchangerForm:setActive()
    end)
    local shopWithdrawButton = ShopForm:addButton(54, 23, " Обменять ", function()
        itemCounterNumberSelectForm:setActive()
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

BuyShopForm = createBuyShopForm()
OreExchangerForm = createOreExchangerForm()


local Event1 = AutorizationForm:addEvent("player_on", function(e, p)
    if (p) then
        autorize(p)
    end
end)

local Event1 = AutorizationForm:addEvent("player_off", function(e, p)
    AutorizationForm:setActive()
end)

forms.run(AutorizationForm) --запускаем gui


