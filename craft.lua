-- Robocraft version 0.10.8
-- Public Domain
local version = "0.10.8"
local math = require("math")
local shell = require("shell")
local serialization = require("serialization")
local fs = require("filesystem")
local sides = require("sides")
local robot = require("robot")
local component= require("component")
-- Безопасная подгрузка компонентов
local function safeLoadComponents(name)
    if component.isAvailable(name) then
        return component.getPrimary(name)
    else
        return nil, 'ERROR! Компонент '..name..' не найден!'
    end
end
local inv = safeLoadComponents("inventory_controller")
local crafting = safeLoadComponents("crafting")
local database = safeLoadComponents("database")

if inv == nil then
    print("Ошибка! Нет улучшения «Контроллер инвентаря».")
    os.exit(1)
end

if crafting == nil then
    print("Ошибка! Нет улучшения «Верстак».")
    os.exit(1)
end

if database == nil then
    print("Ошибка! Нет улучшения «База данных».")
    os.exit(1)
end

local args, options = shell.parse(...)

local BASE_DIR = shell.getWorkingDirectory()

local STORAGE_SIDE = sides.forward
RESULT_SLOT = 4

function printf(s, ...)
    return io.write(s:format(...))
end

function sprintf(s, ...)
    return s:format(...)
end

function gridSlot(slot)
    if slot <= 3 then
        return slot
    elseif slot <=6 then
        return slot + 1
    elseif slot <=9 then
        return slot +2
    end
end

function loadFile(fn)
    local _err = function(err)
        return nil, sprintf("Не могу загрузить файл <%s> (%s)", fn, err)
    end
    local f, err = io.open(fn, "rb")
    if err ~= nil then return _err(err) end
    local content, err = f:read("*all")
    if err ~= nil then return _err(err) end
    local _, err = f:close()
    if err ~= nil then return _err(err) end
    return content
end

function saveFile(fn, data)
    local _err = function(err)
        return nil, sprintf("Не могу сохранить файл <%s> (%s)", fn, err)
    end
    local f, err = io.open(fn, "wb")
    if err ~= nil then return _err(err) end
    local _, err = f:write(data)
    if err ~= nil then return _err(err) end
    local _, err = f:close()
    if err ~= nil then return _err(err) end
end

do
    local databaseSlot = 1

    itemdb = { }
    local items = { }
    local itemsDir = fs.concat(BASE_DIR, "itemdb2")
    local itemsDirOld = fs.concat(BASE_DIR, "itemdb")

    local function convert()
        local function loadItem(itemHash)
            local fn = fs.concat(itemsDirOld, itemHash)
            if fs.exists(fn) then
                local raw, err = loadFile(fn)
                if err ~= nil then
                    printf("Ошибка! Не могу загрузить информацию о предмете <%s> (%s).\n",
                        itemHash, err)
                    os.exit(1)
                end
                return serialization.unserialize(raw)
            end
        end
        local function makeId(item)
            local id = item.name
            if item.maxDamage > 0 then
                return id
            end
            id = id.."@"..item.damage
            return id
        end
        local function hashToId(hash)
            local item = loadItem(hash)
            return makeId(item)
        end
        for name in fs.list(itemsDirOld) do
            local item = loadItem(name)
            local item2 = { }
            for key, v in pairs(item) do
                if key == "recipe" then
                    item2.recipe = { n = item.recipe.n, grid = { } }
                    for slot, hash in pairs(item.recipe.grid) do
                        item2.recipe.grid[slot] = hashToId(hash)
                    end
                elseif key == "hash" or key == "aspects" then
                else
                    item2[key] = v
                end
            end
            item2.id = makeId(item2)
            item2.changed = true
            itemdb.saveItem(item2)
        end
        for name in fs.list(BASE_DIR) do
            local hash, err = loadFile(name)
            if hash and string.len(hash) == 64 then
                saveFile(name, hashToId(hash))
            end
        end
    end

    local function init( ... )
        if not fs.exists(itemsDir) then
            local ok, err = fs.makeDirectory(itemsDir)
            if err ~= nil then
                printf("Ошибка! Не могу создать каталог для бд предметов (%s).", err)
                os.exit(1)
            end
            if fs.exists(itemsDirOld) then
                convert()
            end
        end
    end

    function itemdb.flush()
        for itemId, item in pairs(items) do
            if item.changed then
                print("Обновлён:", item.label, item.id)
                if not itemdb.saveItem(item) then
                    return false
                end
                itemdb.makeLabel(item)
            end
        end
        return true
    end

    local function fixFileName(fn)
        local fn = string.gsub(fn, '[ <>:"/\\|?*]', "_")
        return fn
    end

    function itemdb.loadItem(itemId)
        local fn = fs.concat(itemsDir, fixFileName(itemId))
        if fs.exists(fn) then
            local raw, err = loadFile(fn)
            if err ~= nil then
                printf("Ошибка! Не могу загрузить информацию о предмете <%s> (%s).\n",
                    itemId, err)
                os.exit(1)
            end
            return serialization.unserialize(raw)
        end
    end

    function itemdb.saveItem(item)
        if item.changed then
            local fn = fs.concat(itemsDir, fixFileName(item.id))
            print(fn)
            item.changed = nil --TODO use xpcall
            local err = saveFile(fn, serialization.serialize(item))
            if err then
                item.changed = true
                printf("Ошибка! Не могу сохранить информацию о предмете <%s> (%s).\n",
                    itemId, err)
                return false
            end
        end
        return true
    end

    local function computeId(stack)
        local id = stack.name
        if stack.maxDamage > 0 then
            return id
        end
        id = id.."@"..stack.damage
        return id
    end

    local function get(stack)
        local itemId = computeId(stack)
        local item = items[itemId]
        if item == nil then
            item = itemdb.loadItem(itemId)
            if item == nil then
                item = stack
                item.tag = nil
                item.size = nil
                item.charge = nil
                item.aspects = nil --useless thaumcraft info
                item.id = itemId
                item.changed = true
            end
            items[itemId] = item
        end
        return item
    end

    function itemdb.storeInternal(slot)
        local stack = inv.getStackInInternalSlot(slot)
        if not stack then return nil end
        return get(stack)
    end

    function itemdb.store(slot)
        local stack = inv.getStackInSlot(STORAGE_SIDE, slot)
        if not stack then return nil end
        return get(stack)
    end

    function itemdb.get(itemId)
        local item = items[itemId]
        if item == nil then
            item = itemdb.loadItem(itemId)
            if item ~= nil then
                items[itemId] = item
            end
        end
        return item
    end

    function itemdb.all()
        return items
    end

    local function makeLabelFileName(item)
        local fn = fixFileName(item.label)
        fn = fs.concat(BASE_DIR, fn)
        return fn
    end

    function itemdb.makeLabel(item)
        local fn = makeLabelFileName(item)
        local w = true
        if fs.exists(fn) then
            local itemId, err = loadFile(fn)
            if err ~= nil then
                print(err)
                os.exit(1)
            end
            local currentItem = itemdb.loadItem(itemId)
            w = currentItem.recipe == nil or item.recipe ~= nil
        end
        if w then
            saveFile(fn, tostring(item.id))
        end
    end

    function itemdb.makeAllLabels()
        for name in fs.list(itemsDir) do
            local item = itemdb.loadItem(name)
            itemdb.makeLabel(item)
        end
    end

    function itemdb.printReport()
        for name in fs.list(itemsDir) do
            local item = itemdb.loadItem(name)
            local m = ""
            if item.recipe ~= nil then
                m = "!"
            end
            printf("%s%s/%s", m, string.sub(item.id, 1, 6), item.label)
        end
    end

    function itemdb.computeHash(slot)
        inv.store(STORAGE_SIDE, slot, database.address, databaseSlot)
        return database.computeHash(databaseSlot)
    end

    function itemdb.computeHashInternal(slot)
        inv.storeInternal(slot, database.address, databaseSlot)
        return database.computeHash(databaseSlot)
    end

    init()
end

do
    storage = {}
    local db

    local storageFn = fs.concat(BASE_DIR, "storage2.db")

    function storage.load()
        if fs.exists(storageFn) then
            local raw, err = loadFile(storageFn)
            db = serialization.unserialize(raw)
            if err ~= nil then
                printf("Ошибка! Не могу загрузить бд хранилища (%s).\n", err)
                os.exit(1)
            end
        end
        if db == nil then db = {freeSlots = {}} end
    end

    function storage.save()
        if not itemdb.flush() then
            print("бд предметов не сохранена. Невозможно сохоанить бд хранилища")
            return
        end
        local err = saveFile(storageFn, serialization.serialize(db))
        if err ~= nil then
            printf("Ошибка! Не могу сохранить бд хранилища (%s).\n", err)
        end
    end

    local function addStack(slot)
        local item = itemdb.store(slot)
        local hash = itemdb.computeHash(slot)
        local stacks = db[item.id]
        if stacks == nil then
            stacks = { slots = { }, size = 0 }
            db[item.id] = stacks
        end
        local stackSize = inv.getSlotStackSize(STORAGE_SIDE, slot)
        stacks.size = stacks.size + stackSize
        stacks.slots[slot] = { size = stackSize, hash = hash }
        db.freeSlots[slot] = nil
    end

    function storage.scanInventory()
        db = {freeSlots = {}}
        local size, err = inv.getInventorySize(STORAGE_SIDE)
        if not size then
            print("Ошибка! Нет сундука ("..err..").")
            os.exit(1)
        end
        for slot = 1, size, 1 do
            if inv.getSlotStackSize(STORAGE_SIDE, slot) > 0 then
                addStack(slot)
            else
                db.freeSlots[slot] = true
            end
        end
    end

    function storage.count(itemId)
        assert(type(itemId)=="string")
        local stacks = db[itemId]
        if stacks == nil then return 0 end
        return stacks.size
    end

    function storage.xcount(itemId)
        assert(type(itemId)=="string")
        local stacks = db[itemId]
        if stacks == nil then return 0 end
        local counts = { }
        for slot, stack in pairs(stacks.slots) do
            counts[stack.hash] = (counts[stack.hash] or 0) +  stack.size
        end
        return stacks.size, counts
    end

    local function checkSlot(slot, itemId, stackSize)
        if itemId ~= nil then
            local item = itemdb.store(slot)
        end
        if (item ~= nil and itemId ~= item.id)
                or inv.getSlotStackSize(STORAGE_SIDE, slot) ~= stackSize then
            print("Данные о хранилище устарели.")
            print("Останов.")
            os.exit(1)
        end
    end

    function storage.suckStack(itemId, count)
        if count == 0 then
            return true
        end
        local hash
        if robot.count() > 0 then
            hash = itemdb.computeHashInternal(robot.select())
        end
        local item = itemdb.get(itemId)
        if count > item.maxSize then
            return false
        end
        local stacks = db[itemId]
        if stacks == nil then
            return false
        end
        local countS = count
        for slot, stack in pairs(stacks.slots) do
            checkSlot(slot, itemId, stack.size)
            if not hash or (hash == stack.hash) then
                if not hash then hash = stack.hash end
                local take = count
                if take > stack.size then
                    take = stack.size
                end
                local internalStack = inv.getStackInInternalSlot(robot.select())
                if internalStack and (take + internalStack.size > internalStack.maxSize) then
                    take = internalStack.maxSize - internalStack.size
                end
                inv.suckFromSlot(STORAGE_SIDE, slot, take)
                stacks.size = stacks.size - take;
                stack.size = stack.size - take;
                if stack.size == 0 then
                    stacks.slots[slot] = nil
                    db.freeSlots[slot] = true
                end
                if stacks.size == 0 then
                    db[itemId] = nil
                end
                count = count - take
                if count == 0 then
                    break
                end
            end
        end
        return (count == 0), countS - count
    end

    function storage.dropStack(count)
        local droppedStack = inv.getStackInInternalSlot(robot.select())
        if droppedStack == nil then
            return false
        end
        if count == nil then
            count = droppedStack.size
        end
        if count > droppedStack.size then
            return false
        end
        local item = itemdb.storeInternal(robot.select())
        local hash = itemdb.computeHashInternal(robot.select())
        local stacks = db[item.id]
        if stacks ~= nil then
            for slot, stack in pairs(stacks.slots) do
                checkSlot(slot, item.id, stack.size)
                if hash == stack.hash then
                    local free = item.maxSize - stack.size
                    local n = count
                    if n > free then
                        n = free
                    end
                    if n > 0 then
                        inv.dropIntoSlot(STORAGE_SIDE, slot, n)
                        stacks.size = stacks.size + n
                        stack.size = stack.size + n
                        count = count - n
                    end
                    if count == 0 then
                        return true
                    end
                end
            end
        end

        for slot, _ in pairs(db.freeSlots) do
            checkSlot(slot, nil, 0)
            inv.dropIntoSlot(STORAGE_SIDE, slot)
            addStack(slot)
            return true
        end

        print("Нет места в хранилище")
        print("Останов.")
        os.exit(1)
    end

    function storage.printReport()
        for id, st in pairs(db) do
            local item = itemdb.get(id)
            if item ~= nil then
                print(item.label, st.size)
            end
        end
    end

end

local deep = 0
function recursiveCraft(requestedItem, requestedCount)
    deep = deep + 1
    printf("(%d) Крафт <%s * %d>:\n", deep, requestedItem.label, requestedCount)
    local recipe = requestedItem.recipe
    if recipe == nil then
        printf("(%d) Невозможно выполнить крафт. Нет рецепта для <%s>\n",
            deep, requestedItem.label)
        return false
    end
    local items = countRecipeItems(recipe)
    local n = math.ceil(requestedCount / recipe.n)
    --подсчёт кол-ва необходимых ресурсов и крафт недостающих
    ::recount::
    local maxSize = math.min(n, requestedItem.maxSize, math.floor(64 / recipe.n))
    local ok = true
    printf("(%d) Подсчёт ресурсов.\n", deep)
    for itemId, nStacks in pairs(items) do
        local item = itemdb.get(itemId)
        local nedded = nStacks * n
        local itemCount, byHash = storage.xcount(itemId)
        if itemCount < nedded  then
            printf("(%d) Нехватает <%s * %d>\n", deep,
                item.label, nedded - itemCount)
            if not recursiveCraft(item, nedded - itemCount) then
                ok = false
                break
            end
            goto recount
        end
        if #byHash > 1 then
            maxSize = 1
        end
        maxSize = math.min(item.maxSize, maxSize)
    end
    if ok then
        printf("(%d) Выполняю крафт.\n", deep)
        ok = craft(requestedItem, n, maxSize, recipe.grid)
        if ok then
            storage.dropStack()
            printf("(%d) Крафт завершён.\n", deep)
        else
            printf("(%d) Ошибка крафта.\n", deep)
        end
    end
    deep = deep - 1
    return ok
end

function craft(requestedItem, inCount, maxSize, grid)
    local inStep = maxSize
    while inCount > 0 do
        local n = inStep
        if inCount < n then
            n = inCount
        end
        for i = 1, 9, 1 do
            local itemId = grid[i]
            if itemId ~= nil then
                robot.select(gridSlot(i))
                if not storage.suckStack(itemId, n) then
                    print("Не могу положить предмет в сетку крафта.")
                    return false
                end
            end
        end
        robot.select(RESULT_SLOT)
        if robot.count() > 0 then
            storage.dropStack()
        end
        if not crafting.craft() then
            return false
        end
        inCount = inCount - n
    end
    return true
end

function countRecipeItems(recipe)
    local counts = {}
    for i = 1, 9, 1 do
        local id = recipe.grid[i]
        if id ~= nil then
            local cnt = counts[id]
            if cnt == nil then
                cnt = 0
            end
            counts[id] = cnt + 1
        end
    end
    return counts
end

function writeRecipe()
    print("Запись рецепта:")

    print("1. Анализ сетки крафта.")
    local recipe = {
        grid = { },
        n = 1
    }
    for i = 1, 9, 1 do
        local slot = 1
        local item = itemdb.storeInternal(gridSlot(i))
        if item ~= nil then
            recipe.grid[i] = item.id
        end
    end

    print("2. Пробный крафт.")
    robot.select(RESULT_SLOT)
    local ok = crafting.craft(1)
    if not ok then
        print("Неверный рецепт.")
        return
    end

    print("3. Сохраняю рецепт.")
    local outItem = itemdb.storeInternal(4)
    local stack = inv.getStackInInternalSlot(4)
    recipe.n = stack.size
    outItem.recipe = recipe
    outItem.changed = true
    print("Имя предмета:", outItem.label)
    print("Хеш предмета:", outItem.id)
    print("Завершено успешно.")
end

function clearWSlots()
    for i = 1, 9, 1 do
        robot.select(gridSlot(i))
        storage.dropStack()
    end
    robot.select(RESULT_SLOT)
    storage.dropStack()
end

function usage()
    print("Использование:")
    print("craft -w", "Запись рецепта, выложенного в ле-вом верхнем углу инвентаря робота.")
    print("craft <файл с хешем предмета> [<Кол-во>]",
        "Выдаёт  предметы. Крафтит недостающие.")
    print("Опции:")
    print("-s", "Отправить результат крафта в хранилище.")
    print("-o", "Не искать в хранилище. Только крафт.")
    print("-u", "Просканировать хранилище.")
    print("-c", "Очистить рабочие слоты робота.")
    print("-r", "Вывести отчёт.")
    print("-l", "Создать файлы с ид. предметов в текущем  каталоге.")
    os.exit(0)
end

function getParams(shift)
    if shift == nil then shift = 0 end
    local requestedCount = 1
    local requestedItem
    if args[1 + shift] ~= nil then
        local fn = args[1 + shift]
        local itemId, err = loadFile(fn)
        if err ~= nil then
            print(err)
            os.exit()
        end
        requestedItem = itemdb.get(itemId)
        if requestedItem == nil then
            print("Нет информации в бд.")
            os.exit()
        end
    end
    if args[2 + shift] ~= nil then
        requestedCount = tonumber(args[2 + shift])
    end
    return requestedItem, requestedCount
end

function cmdGet()
    local requestedItem, requestedCount = getParams()
    local ok = true
    local neddedCraft = requestedCount
    if not options["o"] then
        local itemCount = storage.count(requestedItem.id)
        neddedCraft = neddedCraft - itemCount
        if itemCount < 0 then
            neddedCraft = 0
        end
    end
    if neddedCraft > 0 then
        if not recursiveCraft(requestedItem, neddedCraft) then
            return
        end
    end
    if not options["s"] then
        local count = requestedCount
        for slot = 1, robot.inventorySize() do
            robot.select(slot)
            local n = count
            if n > requestedItem.maxSize then
                n = requestedItem.maxSize
            end
            local _, ntransfered = storage.suckStack(requestedItem.id, n)
            count = count - ntransfered
            if count == 0 then
                break
            end
        end
        if count ~= 0 then
            printf("Инвентарь полный. Выдано %d предметов.\n", requestedCount - count)
        end
    end
end

function main( ... )
    local cmd = false
    if options["version"] then
        print(version)
        os.exit()
    end

    if options["h"] then
        usage()
    end

    storage.load()

    if options["w"] then
        cmd = true
        writeRecipe()
    end

    if options["m"] then
        cmd = true
        if not crafting.craft() then
            print("Неверный рецепт!")
        end
    end

    if options["u"] then
        cmd = true
        print("Обновление информации о доступных ресурсах")
        storage.scanInventory()
        print("Обновление завершено")
    end

    if options["c"] then
        cmd = true
        clearWSlots()
    end

    if args[1] ~= nil then
        cmd = true
        cmdGet()
    end

    if options["r"] then
        cmd = true
        if options["d"] then
            itemdb.printReport()
        else
            storage.printReport()
        end
    end

    if options["l"] then
        cmd = true
        itemdb.makeAllLabels()
    end

    if not cmd then
        usage()
    end

    storage.save()
end

main()
