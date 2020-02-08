local component = require('component')
local event = require('event')
local robot = require('robot')

robot.select(13)

while true do
    local e, c, x, y, n, p = event.pull()

    if (e == 'modem_message') then
        component.crafting.craft(tonumber(p))
    end
end
