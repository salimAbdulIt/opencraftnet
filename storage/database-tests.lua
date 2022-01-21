local fs = require('filesystem')
local shell = require('shell')
local unit = require('unit')
local utils = require('utils')

require('db')

local Tests = {}
local db = DurexDatabase:new("ITEMS")
function beforeTest()
    fs.remove(shell.getWorkingDirectory() .. "/durex")
end

function Tests:createDatabaseTest()
    -- init

    -- execute
    db:createDataBase()

    -- assert
    unit.assertTrue(fs.exists(shell.getWorkingDirectory() .. "/durex"))
    unit.assertTrue(fs.exists(shell.getWorkingDirectory() .. "/durex/ITEMS"))
    unit.assertTrue(fs.exists(shell.getWorkingDirectory() .. "/durex/ITEMS/data"))
    unit.assertTrue(fs.exists(shell.getWorkingDirectory() .. "/durex/ITEMS/index"))
end

function Tests:insertDataTest()
    -- init
    db:createDataBase()

    -- execute
    db:insert("key", 'expected value')

    -- assert
    unit.assertTrue(fs.exists(shell.getWorkingDirectory() .. "/durex/ITEMS/data/key.row"))

    local value = utils.readObjectFromFile(shell.getWorkingDirectory() .. "/durex/ITEMS/data/key.row")
    unit.assertValue('expected value', value)
end

function Tests:selectAllDataTest()
    -- init
    db:createDataBase()
    db:insert("key", 'expected value')

    -- execute
    local result = db:select(nil, nil, nil, nil)

    -- assert
    unit.assertValue(#result, 1)
    unit.assertValue('expected value', result[1])
end

function Tests:selectDataByEqualsTest()
    --init
    db:createDataBase()
    local value1 = { name = 'test1' };
    local value2 = { name = 'test2' };
    db:insert("key1", value1)
    db:insert("key2", value2)

    local clause = {}
    clause.column = "name"
    clause.value = "test2"
    clause.operation = "="

    -- execute
    local result = db:select({ clause }, nil, nil, nil)

    -- assert
    unit.assertValue(#result, 1)
    unit.assertValue(value2, result[1])
end

function Tests:selectDataByStartsFromTest()
    --init
    db:createDataBase()
    local value1 = { name = 'test11' };
    local value2 = { name = 'test22' };
    db:insert("key1", value1)
    db:insert("key2", value2)

    local clause = {}
    clause.column = "name"
    clause.value = "test2"
    clause.operation = "STARTFROM"

    -- execute
    local result = db:select({ clause }, nil, nil, nil)

    -- assert
    unit.assertValue(#result, 1)
    unit.assertValue(value2, result[1])
end

function Tests:deleteAllTest()
    --init
    db:createDataBase()
    local value1 = { name = 'test11' };
    db:insert("key1", value1)


    -- execute
    db:delete(nil)

    -- assert
    unit.assertNil(fs.list(shell.getWorkingDirectory() .. "/durex/ITEMS/data")())
end

function Tests:createIndexTest()
    --init
    db:createDataBase()

    -- execute
    db:createIndex("count", "EXACT")

    -- assert
    unit.assertTrue(fs.exists(shell.getWorkingDirectory() .. "/durex/ITEMS/index/count.EXACT"))
end

function Tests:updateIndexTest()
    --init
    db:createDataBase()
    db:createIndex("count", "EXACT")
    local valueToInsert = { name = 'test', count = 100 };
    local expectedIndex = { ["100"] = { "key1.row" } }

    -- execute
    db:insert("key1", valueToInsert)

    -- assert
    local actualIndex = utils.readObjectFromFile(shell.getWorkingDirectory() .. "/durex/ITEMS/index/count.EXACT")

    unit.assertValue(expectedIndex, actualIndex)
end

function Tests:selectValueWithExactIndexTest()
    --init
    db:createDataBase()
    db:createIndex("count", "EXACT")
    local valueToInsert = { name = 'test', count = 100 };
    db:insert("key1", valueToInsert)

    local clause = {}
    clause.column = "count"
    clause.value = "100"
    clause.operation = "="

    -- execute
    local values = db:select({ clause }, nil, nil, nil)
    -- assert
    unit.assertValue(valueToInsert, values[1])
end

function Tests:selectValueWithTwoExactIndexesTest()
    --init
    db:createDataBase()
    db:createIndex("count", "EXACT")
    db:createIndex("name", "EXACT")
    local valueToInsert1 = { name = 'test1', count = 100 };
    local valueToInsert2 = { name = 'test2', count = 100 };
    local valueToInsert3 = { name = 'test2', count = 200 };
    db:insert("key1", valueToInsert1)
    db:insert("key2", valueToInsert2)
    db:insert("key3", valueToInsert3)

    local clause1 = {}
    clause1.column = "count"
    clause1.value = "100"
    clause1.operation = "="
    local clause2 = {}
    clause2.column = "name"
    clause2.value = "test2"
    clause2.operation = "="

    -- execute
    local values = db:select({ clause1, clause2 }, nil, nil, nil)
    -- assert
    unit.assertValue(1, #values)
    unit.assertValue(valueToInsert2, values[1])
end

function Tests:selectValuesWithOrderTest()
    --init
    db:createDataBase()
    local valueToInsert1 = { name = 'test1', count = 100 };
    local valueToInsert2 = { name = 'test2', count = 500 };
    local valueToInsert3 = { name = 'test3', count = 300 };
    db:insert("key1", valueToInsert1)
    db:insert("key2", valueToInsert2)
    db:insert("key3", valueToInsert3)

    -- execute
    local valuesOrderByCount = db:select(nil, "count", nil, nil)

    -- assert
    unit.assertValue(3, #valuesOrderByCount)
    unit.assertValue(valueToInsert2, valuesOrderByCount[1])
    unit.assertValue(valueToInsert3, valuesOrderByCount[2])
    unit.assertValue(valueToInsert1, valuesOrderByCount[3])
end

function Tests:selectValuesWithOrderAndWithClauseTest()
    --init
    db:createDataBase()

    local valueToInsert1 = { name = 'test1', count = 100 };
    local valueToInsert2 = { name = 'test1', count = 500 };
    local valueToInsert3 = { name = 'test1', count = 300 };
    local valueToInsert4 = { name = 'test2', count = 50 };
    db:insert("key1", valueToInsert1)
    db:insert("key2", valueToInsert2)
    db:insert("key3", valueToInsert3)
    db:insert("key4", valueToInsert4)

    local clause = {}
    clause.column = "name"
    clause.value = "test1"
    clause.operation = "="

    -- execute
    local valuesOrderByCount = db:select({ clause }, "count", nil, nil)

    -- assert
    unit.assertValue(3, #valuesOrderByCount)
    unit.assertValue(valueToInsert2, valuesOrderByCount[1])
    unit.assertValue(valueToInsert3, valuesOrderByCount[2])
    unit.assertValue(valueToInsert1, valuesOrderByCount[3])
end

unit.runTests(Tests, beforeTest)
