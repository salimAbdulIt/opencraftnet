local component = require('component')
local event = require('event')
local robot = require('robot')

robot.select(13)

local slots = {
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 5,
    [5] = 6,
    [6] = 7,
    [7] = 9,
    [8] = 10,
    [9] = 11,
    [0] = 13
} -- todo move to storage application
while true do
    local e, c, x, y, n, p = event.pull()

    if (e == 'modem_message') then
        component.crafting.craft(tonumber(p))
    end
end
