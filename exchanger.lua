local component = require('component')
local diamond = component.diamond
local pim = component.pim
local me = component.me_interface
local event = require('event')
local trades = {}
local name = 'Durex77'

function reward(id, dmg, count)
    local items = me.getAvailableItems()
    for i=1,#items do
        if (items[i].fingerprint.id == id and items[i].fingerprint.dmg == dmg and items[i].size >= count) then
            item = items[i]
            while count > 0 do
                count = count - me.exportItem(items[i].fingerprint,"UP" , count).size
            end
            return true
        end
    end
    return false
end

function loadTrades()
    trades = {}
    for i=1,40 do
        local item = diamond.getStackInSlot(i*2-1)
        local reward = diamond.getStackInSlot(i*2)

        if (item) then
            local str = item.id .. item.dmg .. item.name
            reward.qtyFrom = item.qty
            trades[str] = reward
        end
    end
end

function getItemCount(id,dmg)
  local items = me.getAvailableItems()
    for i=1,#items do
        if (items[i].fingerprint.id == id and items[i].fingerprint.dmg == dmg ) then
            return items[i].size
        end
    end
    return 0
end

function exchange(slot, tmpItem, rewardItem)
    local times = math.floor(tmpItem.qty/rewardItem.qtyFrom)
    local maxTime = math.floor(getItemCount(rewardItem.id, rewardItem.dmg)/rewardItem.qty)
    if (maxTime < times) then
        times = maxTime
    end
    local pushCount = pim.pushItem('DOWN',slot,times*rewardItem.qtyFrom,1)
    if (pushCount) then
        print(name .. ' обменял ' .. pushCount .. ' ' .. tmpItem.id .. ':' .. tmpItem.dmg .. ' на '  .. pushCount/rewardItem.qtyFrom*rewardItem.qty .. ' ' .. rewardItem.id .. ':' .. rewardItem.dmg)
        reward(rewardItem.id, rewardItem.dmg, pushCount/rewardItem.qtyFrom*rewardItem.qty)
    end
end

function exchangeAll()
    local inv = pim.getAllStacks()
    for i=1,40 do
        local item = inv[i]

        if (item) then
            local str = item.basic().id .. item.basic().dmg .. item.basic().name
            local rewardItem = trades[str]
            if (rewardItem) then
                exchange(i ,item.basic() , rewardItem)
            end
        end
    end
end


loadTrades()

while true do
    local e,nick,_,_ = event.pull('player_on')

    if (nick) then
        name =nick
        exchangeAll()
    end
end

