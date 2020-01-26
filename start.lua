local serial = require("serialization")
args = { ... }
local query = {}
require('durexdb')
local db = DurexDatabase:new()
query.type = args[1]
if (query.type == 'SELECT') then
    query.table = args[3]
    local i = 5
    if (args[i]) then
        query.fields = {}
    end
    while (args[i]) do
        local field = {}
        field.column = args[i]
        field.operation = args[i + 1]
        field.value = args[i + 2]
        table.insert(query.fields, field)
        i = i + 3
    end
end

if (query.type == 'CREATE') then
    query.createType = args[2]
    if (query.createType == 'DATABASE') then
        query.table = args[3]
    elseif (query.createType == 'INDEX') then
        query.name = args[3]
        query.table = args[5]
        query.field = args[6]
        query.indexType = args[7]
    end
end

if (query.type == 'INSERT') then
    query.table = args[3]
    query.id = args[4]
    query.value = serial.unserialize(args[5])
end

if (query.type == 'DELETE') then
    query.table = args[3]

    local i = 5
    if (args[i]) then
        query.fields = {}
    end
    while (args[i]) do
        local field = {}
        field.column = args[i]
        field.operation = args[i + 1]
        field.value = args[i + 2]
        table.insert(query.fields, field)
        i = i + 3
    end
end


db:executeQuery(query)



