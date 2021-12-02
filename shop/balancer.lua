local component = require('component')
local computer = require('computer')
local forms = require("forms") -- подключаем библиотеку
local gpu = component.gpu
local utils = require('utils')
local unicode = require('unicode')
gpu.setResolution(80, 25)
require("balanceService")

local balanceService = BalanceService:new()

local BalanceForm

local timer

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

function createBalanceForm()
    local BalanceForm = forms.addForm()
    BalanceForm.border = 1
    local appFrame = BalanceForm:addFrame(3, 5, 1)
    appFrame.W = 76
    appFrame.H = 18
    local appName = BalanceForm:addLabel(32, 1, " Legend Balance ")
    appName.fontColor = 0x00FDFF
    local authorLabel = BalanceForm:addLabel(32, 25, " Автор: Durex77 ")
    authorLabel.fontColor = 0x00FDFF

    local shopNameLabel = BalanceForm:addLabel(30, 4, " Поддержка ресурсов ")
    local shopCountLabel = BalanceForm:addLabel(4, 6, " Наименование                                                Количество")
    local itemList = BalanceForm:addList(5, 7, function()
    end)

    local items = balanceService:getBalancedItems()
    for i = 1, #items do
        local name = items[i].label
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
        local itemToBalance = itemList.items[itemList.index]
        if (itemToBalance) then
            balanceService:balanceItem(itemToBalance, count)
            BalanceForm = createBalanceForm()
            BalanceForm:setActive()
        end

    end, BalanceForm, " Установить ")

   BalanceForm:addButton(45, 23, " Обновить  ", function()
       balanceService:update()

       BalanceForm = createBalanceForm()
       BalanceForm:setActive()
    end)

    BalanceForm:addButton(68, 23, " Убрать  ", function()
        local itemToBalance = itemList.items[itemList.index]
        if (itemToBalance) then
            balanceService:balanceItem(itemToBalance, 0)
            BalanceForm = createBalanceForm()
            BalanceForm:setActive()
        end
    end)
    local balanceButton = BalanceForm:addButton(56, 23, " Добавить ", function()
        local itemToBalance = itemList.items[itemList.index]
        if (itemToBalance) then
            itemCounterNumberSelectForm:setActive()
        end
    end)
    return BalanceForm
end


BalanceForm = createBalanceForm()

timer = BalanceForm:addTimer(1, function()
    balanceService:balance()
end)

forms.run(BalanceForm) --запускаем gui


