local event = require("event")
require('dlog')

event.shouldInterrupt = function()
    return false
end

while true do
    local result, errorMsg = pcall(loadfile("/home/1.lua"))
    pcall(function()
        endprintD(errorMsg)
    end)
end
