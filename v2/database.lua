local fs = require("filesystem")
local shell = require("shell")
local serial = require("serialization")
local component = require('component')

local IndexedValuesIterator = {}
function IndexedValuesIterator:new(parent, clauses, orderBy)
    local obj1 = {}
    obj1.parent = parent
    obj1.filters = clauses
    obj1.orderBy = orderBy

    function obj1:init()
        self.isContainceKeys = true
        local indexes = self.parent:isIndexExist(clauses)
        local file = io.open(self.parent.indexPath .. clauses[indexes[1]].column .. "." .. self.parent:getIndexType(clauses[indexes[1]].operation))
        local indexedValues1 = serial.unserialize(file:read("*a"))
        file:close()
        local searchValues = self.parent:selectByIndex(indexedValues1, clauses[indexes[1]].value, self.parent:getIndexType(clauses[indexes[1]].operation))
        for i = 2, #indexes do
            local file = io.open(self.parent.indexPath .. clauses[indexes[i]].column .. "." .. self.parent:getIndexType(clauses[indexes[i]].operation))
            local tempIndexedValues = serial.unserialize(file:read("*a"))
            file:close()
            searchValues = self.parent:intersection(searchValues, tempIndexedValues[clauses[indexes[i]].value])
        end
        if (orderBy) then
            local file = io.open(self.parent.indexPath .. orderBy .. ".EXACT") --todo use already loaded index
            if (file) then
                local tempIndexedValues = serial.unserialize(file:read("*a"))
                file:close()
                local mapToIndex = {}
                for k, v in pairs(tempIndexedValues) do
                    for i = 1, #v do
                        mapToIndex[v[i]] = k
                    end
                end

                table.sort(searchValues, function(left, right)
                    return tonumber(mapToIndex[left]) > tonumber(mapToIndex[right])
                end)

                self.isContainceKeys = true
            else
                local allValues = {}
                for i = 1, #searchValues do
                    file = io.open(self.parent.dataPath .. searchValues[i])
                    local value = serial.unserialize(file:read("*a"))
                    file:close()
                    table.insert(allValues, value)
                end

                table.sort(allValues, function(left, right)
                    return left[orderBy] > right[orderBy]
                end)
                self.isContainceKeys = false
                searchValues = allValues
            end
        end
        self.searchValues = searchValues
        self.index = 1
        self.count = #searchValues
    end

    function obj1:next()
        if (self.isContainceKeys) then
            local idOfValue = self.searchValues[self.index]
            self.index = self.index + 1
            if (not idOfValue) then
                return
            end
            local file = io.open(self.parent.dataPath .. idOfValue)
            local value = serial.unserialize(file:read("*a"))
            file:close()
            return value
        else
            local value = self.searchValues[self.index]
            self.index = self.index + 1
            return value
        end
    end

    function obj1:getFilters()
        return self.filters
    end

    function obj1:skip()
        self.index = self.index + 1
    end

    function obj1:getCount()
        return self.count
    end

    setmetatable(obj1, self)
    obj1:init()
    self.__index = self; return obj1
end

local ValuesIterator = {}
function ValuesIterator:new(parent, clauses, orderBy)
    local obj1 = {}
    obj1.parent = parent
    obj1.filters = clauses

    function obj1:init()
        local searchValues = {}
        if (orderBy) then
            local file = io.open(self.parent.indexPath .. orderBy .. '.EXACT')
            if (file) then
                local tempIndexedValues = serial.unserialize(file:read("*a"))
                file:close()
                local sortedList = {}
                for k, v in pairs(tempIndexedValues) do
                    for i = 1, #v do
                        local tempItem = {}
                        tempItem[1] = k
                        tempItem[2] = v[i]
                        table.insert(sortedList, tempItem)
                    end
                end


                table.sort(sortedList, function(left, right)
                    return tonumber(left[1]) > tonumber(right[1])
                end)
                for i = 1, #sortedList do
                    searchValues[i] = sortedList[i][2]
                end
                self.isContainceKeys = true
            else
                for item in (fs.list(self.parent.dataPath)) do
                    file = io.open(self.parent.dataPath .. item)
                    local tempValue = serial.unserialize(file:read("*a"))
                    file:close()
                    table.insert(searchValues, tempValue)
                end
                table.sort(searchValues, function(left, right)
                    return left[orderBy] > right[orderBy]
                end)
                self.isContainceKeys = false
            end
        else
            for item in (fs.list(self.parent.dataPath)) do
                table.insert(searchValues, item)
            end
            self.isContainceKeys = true;
        end

        self.searchValues = searchValues
        self.index = 1
        self.count = #searchValues
    end

    function obj1:next()
        if (self.isContainceKeys) then
            local idOfValue = self.searchValues[self.index]
            self.index = self.index + 1
            if (not idOfValue) then
                return
            end
            local file = io.open(self.parent.dataPath .. idOfValue)
            local value = serial.unserialize(file:read("*a"))
            file:close()
            return value
        else
            local value = self.searchValues[self.index]
            self.index = self.index + 1
            return value
        end
    end

    function obj1:getFilters()
        return self.filters
    end

    function obj1:skip()
        self.index = self.index + 1
    end

    function obj1:getCount()
        return self.count
    end

    setmetatable(obj1, self)
    obj1:init()
    self.__index = self; return obj1
end

DurexDatabase = {}
function DurexDatabase:new(tableName)
    local obj = {}

    function obj:save()
    end

    function obj:read()
    end

    function obj:init()
        self.fullPath = shell.getWorkingDirectory() .. "/durex/" .. tableName .. "/"
        self.dataPath = shell.getWorkingDirectory() .. "/durex/" .. tableName .. '/data/'
        self.indexPath = shell.getWorkingDirectory() .. "/durex/" .. tableName .. '/index/'
        self:createDataBase()
    end

    function obj:createDataBase()
        if (not fs.exists(shell.getWorkingDirectory() .. "/durex")) then
            fs.makeDirectory(shell.getWorkingDirectory() .. "/durex")
        end
        if (not fs.exists(self.fullPath)) then
            fs.makeDirectory(self.fullPath)
        end
        if (not fs.exists(self.dataPath)) then
            fs.makeDirectory(self.dataPath)
        end
        if (not fs.exists(self.indexPath)) then
            fs.makeDirectory(self.indexPath)
        end
    end

    function obj:createIndex(field, indexType)
        self:initIndex(field, indexType)
    end

    function obj:initIndex(field, indexType)
        local indexedValues = {}
        local elements = fs.list(self.dataPath)
        for element in (elements) do
            local file = io.open(self.dataPath .. "/" .. element, "r")
            local indexedValue, value = self:indexValue(serial.unserialize(file:read("*a")), element, field .. '.' .. indexType)
            if (not indexedValues[indexedValue]) then
                indexedValues[indexedValue] = {}
            end
            table.insert(indexedValues[indexedValue], value)
            file:close()
        end
        local file = io.open(self.indexPath .. field .. "." .. indexType, "w")
        file:write(serial.serialize(indexedValues))
        file:close()
    end

    function obj:intersection(n, m)
        local r = {}
        for i1, v1 in pairs(m) do
            for i2, v2 in pairs(n) do
                if (v1 == v2) then

                    table.insert(r, v1)
                    break
                end
            end
        end
        return r
    end

    function obj:indexValue(value, pathToValue, key)
        local words = {}
        for word in key:gmatch("%w+") do table.insert(words, word) end
        if ("EXACT" == words[2]) then
            return tostring(value[words[1]]), pathToValue:gsub(":", "")
        end
        if ("STARTFROM" == words[2]) then
            return tostring(value[words[1]]), pathToValue:gsub(":", "")
        end
    end

    function obj:insert(id, value)
        local oldValue;
        if (fs.exists(self.dataPath .. id .. ".row")) then
            local file = io.open(self.dataPath .. id .. ".row", "r")
            oldValue = serial.unserialize(file:read("*a"))
            file:close()
        end
        self:updateIndexValues(oldValue, value, id .. ".row")
        oldValue = nil
        local file = io.open(self.dataPath .. id .. ".row", "w")
        file:write(serial.serialize(value))
        file:close()
    end

    function obj:insertAll(id, values) -- todo realize
    end

    function obj:tablefind(tab, el)
        for index, value in pairs(tab) do
            if value == el then
                return index
            end
        end
    end

    function obj:clearIndexes()
        for index in (fs.list(self.indexPath)) do
            local file = io.open(self.indexPath .. index, "w")
            file:write('')
            file:close()
        end
    end

    function obj:updateIndexValues(oldItem, newItem, name)
        for index in (fs.list(self.indexPath)) do
            local file = io.open(self.indexPath .. index, "r")
            local indexedValues = serial.unserialize(file:read("*a"))
            if (not indexedValues) then
                indexedValues = {}
            end
            file:close()
            if (oldItem) then
                local indexedValue, value = self:indexValue(oldItem, name, index)
                table.remove(indexedValues[indexedValue], self:tablefind(indexedValues[indexedValue], value))
            end
            file = io.open(self.indexPath .. index, "w")
            if (newItem) then
                local indexedValue, value = self:indexValue(newItem, name, index)
                if (not indexedValues[indexedValue]) then
                    indexedValues[indexedValue] = {}
                end
                table.insert(indexedValues[indexedValue], value)
            end
            file:write(serial.serialize(indexedValues))
            file:close()
        end
    end

    function obj:selectById(id)
        local path = self.dataPath .. id .. ".row"
        if (not fs.exists(path)) then
            return nil
        end

        local file = io.open(path, "r")
        local data = serial.unserialize(file:read("*a"))
        file:close()
        return data
    end

    function obj:selectFromObject(object, skip, limit)
        local tempSkip = skip or 0
        local tempLimit = limit or 10000
        local filters = object:getFilters()
        local resultValues = {}
        if (object:getCount() == 0) then
            return resultValues
        end

        if (not filters) then
            for i = 1, tempSkip or 0 do
                object:skip()
            end
            tempSkip = 0
        end

        local value = object:next()
        repeat
            local isItemValid = true
            if (filters) then
                for j, field in pairs(filters) do
                    if (not self:isValid(value[field.column], field.value, field.operation)) then
                        isItemValid = false
                        break
                    end
                end
            end

            if (isItemValid) then
                if (tempSkip > 0) then
                    tempSkip = tempSkip - 1
                else
                    if (tempLimit > 0) then
                        tempLimit = tempLimit - 1
                        table.insert(resultValues, value)
                    end
                    if (tempLimit == 0) then
                        return resultValues
                    end
                end
            end
            value = object:next()
        until (not value)
        return resultValues
    end

    function obj:selectByIndex(indexValues, searchValue, indexType)
        if (indexType == "EXACT") then
            return indexValues[searchValue]
        elseif (indexType == "STARTFROM") then
            local result = {}
            for k, v in pairs(indexValues) do
                if (self:isValid(k, searchValue, indexType)) then
                    for i, v1 in pairs(v) do
                        table.insert(result, v1)
                    end
                end
            end
            return result
        end
    end

    function obj:select(clauses, orderBy, skip, limit)
        local resultValue = {}
        local sortedValues = {}
        if (clauses and clauses[1].column == "ID") then
            local value = self:selectById(clauses[1].value)
            if (value) then
                table.insert(resultValue, value)
            end
        elseif (self:isIndexExist(clauses)) then
            return self:selectFromObject(IndexedValuesIterator:new(self, clauses, orderBy), skip, limit)
        else
            return self:selectFromObject(ValuesIterator:new(self, clauses, orderBy), skip, limit)
        end
        if (orderBy) then --todo is it valid?
            table.sort(sortedValues, function(left, right)
                return left[orderBy] > right[orderBy]
            end)

            for i = skip, math.min(skip + limit, #sortedValues) do
                table.insert(resultValue, sortedValues[i])
            end
        end
        return resultValue
    end

    function obj:getIndexType(operation)
        if (operation == '=') then
            return "EXACT"
        elseif (operation == 'STARTFROM') then
            return 'STARTFROM'
        end
    end

    function obj:isIndexExist(clauses)
        if clauses == null then
            return false
        end
        local indexes = {}
        for index, value in pairs(clauses) do
            if (fs.exists(self.indexPath .. "/" .. value.column .. "." .. self:getIndexType(value.operation))) then
                table.insert(indexes, index)
            end
        end
        if (#indexes > 0) then
            return indexes
        end
        return false
    end

    function obj:starts_with(str, start)
        return str:sub(1, #start) == start
    end

    function obj:isValid(value1, value2, operation)
        if (operation == "=") then
            return tostring(value1) == tostring(value2)
        elseif (operation == "STARTFROM") then
            local result = self:starts_with(string.lower(value1), string.lower(value2))
            local a = 'false'
            if (result) then a = 'true' end
            return result
        end
    end

    function obj:delete(clauses)
        if (clauses) then

        else
            local elements = fs.list(self.dataPath)
            for element in (elements) do
                fs.remove(self.dataPath .. "/" .. element)
            end
            self:clearIndexes()
        end
    end

    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
