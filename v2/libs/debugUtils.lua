local component = require('component')
local debug = component.debug
local world = debug.getWorld(0)

local utils = {}

utils.setBlock = function(x, y, z, id, dmg)
    world.setBlock(x, y, z, id, dmg)
end

utils.insertItem = function(x, y, z, slot, id, dmg, nbt, count)
    for i=1,slot-1 do
        world.insertItem(id, 64, dmg, nbt, x, y, z, 1)
    end
    world.insertItem(id, count, dmg, nbt, x, y, z, 1)
    for i=1,slot-1 do
        world.removeItem(x, y, z, i-1)
    end
end

utils.removeItem = function(x, y, z, slot)
    world.removeItem(x, y, z, slot)
end

utils.getItem = function(x, y, z, slot)
    local nbt = world.getTileNBT(x, y, z)
    if nbt.value['Items'] then
        local inventory = nbt.value['Items'].value
        for num, item in ipairs(inventory) do
            if item.value.Slot.value == slot then
                local itemToReturn = {}
                for k,v in pairs(item.value) do
                    itemToReturn[k] = v.value
                end
                return itemToReturn
            end
        end
    end
end

utils.getOCComponentAddress = function(x, y, z)
    return world.getTileNBT(x, y, z).value.node.value.address.value
end

return utils
