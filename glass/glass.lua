local component = require('component')
local g = component.openperipheral_bridge
local event = require('event')
local internet = component.internet
local bosses = {
    {
        name = "ZEZ",
        cooldown = 60 * 24,
        title = "lol",
        color = 0xFF0000
    },
    {
        name = "VALIRE",
        cooldown = 60 * 20,
        title = "lol",
        color = 0xFF0000
    },
    {
        name = "ЦУРИ",
        cooldown = 700,
        title = "lol",
        color = 0xFF0000
    },
    {
        name = "СУШКА",
        cooldown = 700,
        title = "lol",
        color = 0xFF0000
    },
    {
        name = "Урабчик",
        cooldown = 60 * 15,
        title = "lol",
        color = 0xFF0000
    },
    {
        name = "Ральф",
        cooldown = 60 * 10,
        title = "lol",
        color = 0x999900
    },
    {
        name = "Брекет",
        cooldown = 60 * 15,
        title = "lol",
        color = 0x999900
    },
    {
        name = "Снежный ком",
        cooldown = 60 * 15,
        title = "lol",
        color = 0x999900
    },
    {
        name = "Орк",
        cooldown = 60 * 15,
        title = "lol",
        color = 0x999900
    },
    {
        name = "Охрана улица",
        cooldown = 60 * 4,
        title = "lol",
        color = 0x000000
    },
    {
        name = "Охрана дом",
        cooldown = 60 * 4,
        title = "lol",
        color = 0x000000
    }
}

local function clean()
    g.clear()
end

local function buildGui()
    for i = 1, #bosses do
        bosses[i].kill = g.addText(30, 5 + (i * 17), "X")
        bosses[i].kill.setScale(2)
        bosses[i].kill.setAlpha(0.5)

        local text = g.addText(50, 5 + (i * 17), bosses[i].name)
        text.setScale(2)
        text.setAlpha(0.5)

        bosses[i].timer = g.addText(200, 5 + (i * 17), 'HZ')
        bosses[i].timer.setScale(2)
        bosses[i].timer.setAlpha(0.7)
        bosses[i].timer.setColor(bosses[i].color)

        bosses[i].time = 0
    end
end

clean()
buildGui()

local function getTime()
    local response =  internet.request("http://durex77.pythonanywhere.com/krov/get/time")
    local text = ""
    local respText = response.read(99999)
    while respText do
        text = text .. respText
        respText = response.read(99999)
    end
    return tonumber(text)
end

local function recount()
    local now = getTime()
    for i = 1, #bosses do
        local newTime = math.floor(bosses[i].cooldown - (now - bosses[i].time))
        if (newTime < 0) then
            newTime = "HZ"
        else
            local seconds = newTime%60
            newTime = math.floor((newTime / 60)) .. ':' .. seconds > 9 and seconds or ('0' .. seconds)
        end
        bosses[i].timer.setText(newTime)
    end
end

g.sync()

while true do
    local e, a, n, a2, id = event.pull(1)
    if (e and e == "glasses_component_mouse_up") then
        for i = 1, #bosses do
            if (bosses[i].kill.getId() == id) then
                bosses[i].time = getTime()
                break
            end
        end
    end
    pcall(function()
        recount()
    end)
    g.sync()
end
