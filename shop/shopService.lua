local component = require('component')
require('database')
ShopService = {}
function ShopService:new()
    local obj = {}

    function obj:init()
        self.db = DurexDatabase:new("USERS")
    end

    function obj:dbClause(fieldName, fieldValue, typeOfClause)
        local clause = {}
        clause.column = fieldName
        clause.value = fieldValue
        clause.operation = typeOfClause
        return clause
    end

    function obj:getBalance(nick)
        local itemsFromDb = self.db:select({ self:dbClause("ID", nick, "=") })
        if (itemsFromDb[1]) then
            return itemsFromDb[1].balance
        end
        return 0
    end

    function obj:getItemCount(nick)
        local itemsFromDb = self.db:select({ self:dbClause("ID", nick, "=") })
        if (itemsFromDb[1]) then
            return itemsFromDb[1].itemCount
        end
        return 0
    end


    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
