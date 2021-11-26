local robot = require('robot')
local os = require(os)
local Robot = {}

local coords = { x = 0, y = 0, z = 0 , side = 3}; -- front(3), right(4), left(2), back(5)

function Robot:new()
    local obj = {}

    function obj:init()

    end

    function obj:executeAction(action, attNum, failBack, ...)
        for i = 1, attNum or 1 do
            while not action(...) do
                if (failBack) then
                    failBack()
                else
                    os.sleep(0.25)
                end
            end
        end
    end

    function obj:forward(attNum)
        self:executeAction(robot.forward, attNum, nil)
    end

    setmetatable(obj, self)
    obj:init()
    self.__index = self;
    return obj
end
