local component = require('component')
local debug = component.debug
local world = debug.getWorld(0)

local utils = {}

utils.setBlock = function(x, y, z, id, dmg)
    world.setBlock(x, y, z, id, dmg)
end

utils.insertItem = function(x, y, z, slot, id, dmg, nbt, count)
    world.insertItem(id, count, dmg, nbt, x, y, z, 1)
end

return utils
