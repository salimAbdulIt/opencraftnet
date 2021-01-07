
local s = require('l')

local a = {}
a.name = 'minecraft:diamond'
a.dmg = 1
a.size = 0
a.xdata = {}
a.xdata["test"] = {}
a.xdata["test"][1] = {}
a.xdata["test"][2] = {}
a.xdata["test"][1].size = 10
a.xdata["test"][2].size = 13

s:save('testFile', a)









local s = require('l')

local ser = require('serialization')
print(ser.serialize(s:read('testFile')))
