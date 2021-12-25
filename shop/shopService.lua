local component = require('component')
local thread = require('thread')
local event = require('event')
local internet = require('internet')
local chat = component['chat_box']


local server_url = 'http://45.82.152.216:5001'
chat.setName("§4discord§6")
thread.init()


local function get(url)
    local response = internet.request(url)
    local result = ''
    for i=1, 3 do
        local response_check = response.read(99999)
        if response_check then
            result = result .. response_check
        end
    end
    return result
end


thread.create(function()
    while true do
        local act = {event.pull()}
        if act[1] == 'chat_message'then
            internet.request(server_url .. '/send_minecraft', {["msg"]=act[3] .. ': ' .. act[4]:gsub("&", "§")})
        end
    end
end)


os.execute("cls")
print('Chat ds by OB1CHAM v 1.05')
while true do
    local msg = get(server_url .. '/read_minecraft')
    if msg ~= 'None' and msg ~= '' then
        chat.say(msg)
    end
    os.sleep(0.1)
end
