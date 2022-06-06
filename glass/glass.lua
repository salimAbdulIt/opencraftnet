local component = require('component')
local g = component.openperipheral_bridge
local event = require('event')
local internet = component.internet

local scale = 2
local betweenLines = 17
local bosses = {
    {
        name = "Ада",
        cooldown = 60 * 30,
        title = "lol",
        color = 0xFF0000
    },
    {
        name = "Зез",
        cooldown = 60 * 24,
        title = "lol",
        color = 0xFF0000
    },
    {
        name = "Мефисто",
        cooldown = 60 * 23,
        title = "lol",
        color = 0xFF0000
    },
    {
        name = "Валир",
        cooldown = 60 * 20,
        title = "lol",
        color = 0xFF0000
    },
    {
        name = "Абаддон",
        cooldown = 60 * 30,
        title = "lol",
        color = 0xFF0000
    },
    {
        name = "Цури",
        cooldown = 700,
        title = "lol",
        color = 0xFF0000
    },
    {
        name = "Сушка",
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
}

local function clean()
    g.clear()
end

local function buildGui()
    for i = 1, #bosses do
        bosses[i].kill = g.addText(30, 5 + (i * betweenLines), "X")
        bosses[i].kill.setScale(scale)
        bosses[i].kill.setAlpha(0.5)

        local text = g.addText(50, 5 + (i * betweenLines), bosses[i].name)
        text.setScale(scale)
        text.setAlpha(0.5)

        bosses[i].timer = g.addText(200, 5 + (i * betweenLines), 'HZ')
        bosses[i].timer.setScale(scale)
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
            newTime = math.floor((newTime / 60)) .. ':' .. ((seconds > 9) and seconds or ('0' .. seconds))
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
