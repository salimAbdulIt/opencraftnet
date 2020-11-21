local robot = require('robot')
local component = require('component')
local inv = component.inventory_controller

local length = 25
local chargerSlot = 2
local pickSlot = 3
local function roboAction(action, attNum, ...)
	for i=1, attNum or 1 do
		while not action(...) do
		    if (action == robot.forward) then
		        robot.use()
		    end
			os.sleep(0.25)
		end
	end
end


function suck()
   component.tractor_beam.suck()
 component.tractor_beam.suck()
end


function digLine(n)
    robot.use()
    for i=1,n do
        roboAction(robot.useUp)
        roboAction(robot.forward)
    end
end

function digDoubleLine(n)
    digLine(n)
    roboAction(robot.turnRight)
    roboAction(robot.use)
    roboAction(robot.forward)
    roboAction(robot.turnRight)
    digLine(n)
    roboAction(robot.turnLeft)
    roboAction(robot.use)
    roboAction(robot.forward)
    roboAction(robot.turnLeft)
end



function rechargeLaser()
    robot.select(chargerSlot)
    roboAction(robot.place)
    robot.select(1)
    inv.equip()
    inv.dropIntoSlot(3,1,1)
    inv.suckFromSlot(3,1,1)
    robot.select(pickSlot)
    inv.equip()
    robot.select(chargerSlot)
    roboAction(robot.swing)
    robot.select(pickSlot)
    inv.equip()
    robot.select(1)
    inv.equip()
end


function refuel()
    for i=1,robot.inventorySize() do
        local item = inv.getStackInInternalSlot(i)
        if (item and item.name == 'minecraft:coal') then
            component.generator.insert(64)
        return
        end
    end
end


function main()
    print("start")
    for i=1,32 do
        digLine(16)
    end
end

--main()
function main2()
for j=1,24 do
    for i=1,47 do
        roboAction(robot.useDown)
        roboAction(robot.forward)
    end
    roboAction(robot.useDown)
    roboAction(robot.turnRight)
    roboAction(robot.forward)
    roboAction(robot.turnRight)
    for i=1,47 do
            roboAction(robot.useDown)
            roboAction(robot.forward)
        end
    roboAction(robot.useDown)
    roboAction(robot.turnLeft)
    roboAction(robot.forward)
    roboAction(robot.turnLeft)
end
end
main2()
