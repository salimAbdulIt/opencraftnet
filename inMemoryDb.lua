local fs = require("filesystem")
local shell = require("shell")
local serial = require("serialization")
local databases = {}
databases['ITEMS'] = {}
DurexDatabase = {}
function DurexDatabase:new()
    local obj = {}

    function obj:init(value)
        self.fullPath = shell.getWorkingDirectory() .. "/durex/" .. value.table .. "/"
        self.query = value

        if (not self.query.limit) then
            self.query.limit = 10000
        end
        if (not self.query.skip) then
            self.query.skip = 0
        end
    end

    function obj:save()
        local file = io.open(shell.getWorkingDirectory() .. "/data.backup", "w")
        file:write(serial.serialize(databases))
        file:close()
    end

    function obj:read()
        local file = io.open(shell.getWorkingDirectory() .. "/data.backup", "r")
        if file then
            databases = serial.unserialize(file:read("*a"))
            file:close()
        end
    end



    function obj:executeQuery(value)
        self:init(value);
        if (self.query.type == "SELECT") then
            return self:selectQ()
        elseif (self.query.type == "INSERT") then
            self:insert()
        elseif (self.query.type == "CREATE") then
            if (self.query.createType == "DATABASE") then
                self:createDataBase()
            elseif (self.query.createType == "INDEX") then
                self:createIndex()
            end
        elseif (self.query.type == "DELETE") then
            self:delete()
        end
    end

    function obj:createDataBase()
        databases = {}
        databases['ITEMS'] = {}
    end

    function obj:createIndex()
    end

    function obj:initIndex()
    end

    function obj:indexValue(value, pathToValue, key)
    end

    function obj:insert()
        databases['ITEMS'][self.query.id] = self.query.value
    end


    function obj:insertWithLimits(resultValue, tempValue)
        if (self.query.skip > 0) then
            self.query.skip = self.query.skip - 1
        else
            if (self.query.limit == 0) then
                return false
            end
            self.query.limit = self.query.limit - 1
            table.insert(resultValue, tempValue)
        end
        return true
    end

    function obj:tablefind(tab, el)
        for index, value in pairs(tab) do
            if value == el then
                return index
            end
        end
    end

    function obj:clearIndexes()
    end

    function obj:updateIndexValues(oldItem, newItem, name)
    end

    function obj:selectById(resultValue)
        local item = databases['ITEMS'][self.query.fields[1].value]
        table.insert(resultValue, item)
    end

    function obj:selectFromObject(object)
        object:init()
        local resultValues = {}
        if (object:getCount() == 0) then
            return resultValues
        end

        local value = object:next()
        repeat
            local isItemValid = true
            local filters = object:getFilters()
            if (filters) then
                for j, field in pairs(filters) do
                    if (not self:isValid(value[field.column], field.value, field.operation)) then
                        isItemValid = false
                        break
                    end
                end
            end

            if (isItemValid) then
                if (not self:insertWithLimits(resultValues, value)) then
                    return resultValues
                end
            end
            value = object:next()
        until (not value)
        return resultValues
    end

    function obj:selectQ()
        local resultValue = {}
        if (self.query.fields and self.query.fields[1].column == "ID") then
            self:selectById(resultValue)
        else
            local values = {}
            function values:new(parent)
                local obj1 = {}
                obj1.parent = parent

                function obj1:init()
                    local searchValues = {}
                    if (self.parent.query.orderBy) then
                        for id, item in pairs(databases['ITEMS']) do
                            table.insert(searchValues, item)
                        end
                        table.sort(searchValues, function(left, right)
                            return left[self.parent.query.orderBy] > right[self.parent.query.orderBy]
                        end)
                    else
                        for id, item in pairs(databases['ITEMS']) do
                            table.insert(searchValues, item)
                        end
                    end
                    self.searchValues = searchValues
                    self.index = 1
                    self.filters = self.parent.query.fields
                    self.count = #searchValues
                end

                function obj1:next()
                    local value = self.searchValues[self.index]
                    self.index = self.index + 1
                    return value
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
                self.__index = self; return obj1
            end

            return self:selectFromObject(values:new(self))
        end
        return resultValue
    end

    function obj:getIndexType(operation)
    end

    function obj:isIndexExist(fields)
    end

    function obj:starts_with(str, start)
        return str:sub(1, #start) == start
    end

    function obj:isValid(value1, value2, operation)
        if (operation == "=") then
            return tostring(value1) == tostring(value2)
        elseif (operation == "STARTFROM") then
            return self:starts_with(string.lower(value1), string.lower(value2))
        end
    end

    function obj:delete()
        if (self.query.fields) then

        else
            databases['ITEMS'] = {}
        end
    end

    setmetatable(obj, self)
    self.__index = self; return obj
end
