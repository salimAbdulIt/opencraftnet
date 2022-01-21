local unit = require('unit')
local utils = require('utils')

require('lists')

local Tests = {}

function beforeTest()
end

function Tests:toArrayTest()
    -- init
    local array = {1,2,3}
    -- execute
    local result = ListStream
        :new(array)
        :toArray()

    -- assert
    unit.assertValue(result, array)
end

function Tests:filterTest()
    -- init
    local array = {1,2,3}

    -- execute
    local result = ListStream
        :new(array)
        :filter(function(element) return (element == 2)  end)
        :toArray()

    -- assert
    unit.assertValue(1, #result)
    unit.assertValue(2, result[1])
end

function Tests:mapTest()
    -- init
    local array = {1}

    -- execute
    local result = ListStream
        :new(array)
        :map(function(element) return (element * 2)  end)
        :toArray()

    -- assert
    unit.assertValue(1, #result)
    unit.assertValue(2, result[1])
end

function Tests:groupByTest()
    -- init
    local el1 = {["name"]= "Test1", ["count"]= 1}
    local el2 = {["name"]= "Test2", ["count"]= 2}
    local el3 = {["name"]= "Test1", ["count"]= 3}
    local array = {el1,el2,el3}

    -- execute
    local result = ListStream
        :new(array)
        :groupBy(function(element) return element["name"], element end)

    -- assert
    unit.assertValue(2, #result["Test1"])
    unit.assertValue(el1, result["Test1"][1])
    unit.assertValue(el3, result["Test1"][2])
    unit.assertValue(1, #result["Test2"])
    unit.assertValue(el2,


    result["Test2"][1])

end

function Tests:containsTest()
    -- init
    local el1 = {["name"]= "Test1", ["count"]= 1}

    local array = {el1}

    -- execute
    local result = ListStream
        :new(array)
        :contains(el1)

    -- assert
    unit.assertTrue(result)
end

function Tests:containsTest_negative()
    -- init
    local el1 = {["name"]= "Test1", ["count"]= 1}
    local el2 = {["name"]= "Test1", ["count"]= 2}

    local array = {el1}

    -- execute
    local result = ListStream
        :new(array)
        :contains(el2)

    -- assert
    unit.assertFalse(result)
end

function Tests:reduceTest()
    -- init
    local el1 = {["count"]= 1}
    local el2 = {["count"]= 2}
    local el3 = {["count"]= 3}
    local array = {el1,el2,el3}

    -- execute
    local result = ListStream
        :new(array)
        :reduce(function(left, right) return left["count"] +  right["count"] end)

    -- assert
    unit.assertValue(6, result)
end

unit.runTests(Tests, beforeTest)
