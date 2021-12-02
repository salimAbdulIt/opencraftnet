local webhook = "https://discord.com/api/webhooks/914944613373083679/_fyWKUpNtEjyzmVVxbaeXBS3SBTGadS3wbFvUigG83xdVMMebZUQ3HOeRGMmhEyzE3f2"
local internet = require('component').internet

function printD(msg)
    local headers = {["User-Agent"]="OpenComputers", ["Content-Type"] = "application/json"}
    msg = string.gsub(msg,'"','//"')
    internet.request(webhook, '{"content": "'.. msg ..'"}', headers, "POST").finishConnect()
end

function uploadFile(path, filename)
    filename = filename or 'upload'
    local f = io.open(path, 'r')
    local text = f:read('*a')
    f:close()
    local data = ('\r\n--------------------------b4ba0694e3cf9579\r\nContent-Disposition: form-data; name="file"; filename="'..filename..'"\r\nContent-Type: text/plain\r\n\r\n%s\n\r\n--------------------------b4ba0694e3cf9579--\r\n'):format(text)
    local headers = {["User-Agent"]="OpenComputers", ["Content-Type"] = "multipart/form-data; boundary=------------------------b4ba0694e3cf9579"}
    internet.request(webhook, data, headers, "POST").finishConnect()
end
