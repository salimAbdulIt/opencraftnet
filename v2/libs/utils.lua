local utils = {}
local serializable = require("serializable")
local shell = require("shell")
local io = require('io')
local filesystem = require("filesystem")

utils.downloadFile = function(url, saveTo, forceRewrite)
    if forceRewrite or not filesystem.exists(saveTo) then
        shell.execute("wget -fq " .. url .. " " .. saveTo)
    end
end

utils.readFromFile = function(filepath)
    local file = io.open(filepath, 'r')
    local value = file:read("a*")
    file:close()
    return value
end

utils.writeObjectToFile = function(filepath, object)
    serializable.serializeToFile(object, filepath)
end

utils.readObjectFromFile = function(filepath)
    return serializable.unserializeFromFile(filepath)
end

return utils
