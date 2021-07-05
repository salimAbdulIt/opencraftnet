
local serial = require("serialization")
local Lists = {}
ListStream = {}
local Tables = {}

function Tables:equals(o1, o2, ignore_mt)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    if not ignore_mt then
        local mt1 = getmetatable(o1)
        if mt1 and mt1.__eq then
            --compare using built in method
            return o1 == o2
        end
    end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or equals(value1, value2, ignore_mt) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

function ListStream:new(array)
    local obj = {}
    obj.array = array

    function obj:filter(filterFunction)
        local newList = {}
        for i, item in pairs(self.array) do
            if (filterFunction(item, i)) then
                table.insert(newList, item)
            end
        end
        obj.array = newList

        return self
    end

    function obj:map(mapFunction)
        for i=1,#self.array do
            self.array[i] = mapFunction(self.array[i], i)
        end

        return self
    end

    function obj:groupBy(groupByFunction)
        local newMap = {}
        for i, item in pairs(self.array) do
            local key, value = groupByFunction(item, i)
            if (not (newMap[key])) then
                newMap[key] = {}
            end
            table.insert(newMap[key], value)
        end
        return newMap
    end

    function obj:contains(element)
        for item in self.array do
            if (Tables:equals(item, element)) then
                return true
            end
        end
        return false
    end

    function obj:reduce(reduceFunction)
        local result = self.array[1]
        for i=2,#self.array do
            result = reduceFunction(result, self.array[i])
        end
        return result
    end

    function obj:toArray(element)
        return self.array
    end

    setmetatable(obj, self)
    self.__index = self; return obj
end



