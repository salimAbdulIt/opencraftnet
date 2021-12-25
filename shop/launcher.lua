local event = require("event")
local gpu = require('component').gpu
require('dlog')

event.shouldInterrupt = function()
    return false
end

while true do
    gpu.setResolution(80, 25)
    local result, errorMsg = pcall(loadfile("/home/1.lua"))
    pcall(function()
        printD(errorMsg)
    end)
end
