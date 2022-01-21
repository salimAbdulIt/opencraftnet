require('database')

local db = DurexDatabase:new("ITEMS")

db:createIndex("count", "EXACT")
db:createIndex("label", "STARTFROM")
