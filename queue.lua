Queue = {}

local typesOfActions = {
    ["transfer"] = 1,
    ["craft"] = 10,
}
local queueCounter = 10

function Queue:new()

    local obj = {}

    function obj:add(type, action, index)
        if (not self.collection) then
            self.collection = {}
        end
        local value = {}
        value.action = action
        value.type = type
        local valueIndex
        if (index) then
            valueIndex = index
        else
            valueIndex = queueCounter
            queueCounter = queueCounter + 1
        end
        self.collection[valueIndex] = value
    end

    function obj:get(type)
        for k, v in pairs(self.collection) do
            if ((not type) or (v.type and v.type == type)) then
                return v.action
            end
        end
    end

    function obj:getAndRemove(type)
        for k, v in pairs(self.collection) do
            if ((not type) or (v.type and v.type == type)) then
                self.collections[k] = nil
                return v.action
            end
        end
    end

    setmetatable(obj, self)
    self.__index = self; return obj
end
