local component = require('component')
require('database')
ShopService = {}
function ShopService:new()
    local obj = {}

    function obj:init()
        self.db = DurexDatabase:new("USERS")
    end

    function obj:getBalance(nick)
        return 1000
    end

    function obj:getItemCount(nick)
        return 100
    end


    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
