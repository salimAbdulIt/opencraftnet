local serial = require("serialization")
local Unit = {}

Unit.toString = function(value)
    local valueType = type(value)
    if (valueType == 'table') then
        return serial.serialize(value)
    elseif (valueType == 'nil') then
        return 'nil'
    else
        return tostring(value)
    end
end

Unit.error = function(expected, actual)
    expected = Unit.toString(expected)
    actual = Unit.toString(actual)
    error("Expected value " .. expected .. " but actual " .. actual)
end

Unit.matchTables = function(t1, t2, ignore_mt)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end
    for k1,v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not Unit.matchTables(v1,v2) then return false end
    end
    for k2,v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not Unit.matchTables(v1,v2) then return false end
    end
    return true
end

Unit.assertValue = function(expected, actual)
    if (type(expected) == 'table' and type(actual) == 'table' and Unit.matchTables(expected, actual)) then
        return 'pass'
    elseif (actual and actual == expected) then
        return 'pass'
    elseif (not actual and not expected) then
        return 'pass'
    end
    Unit.error(expected, actual)
end

Unit.assertTrue = function(value)
    Unit.assertValue(true, value)
end

Unit.assertFalse = function(value)
    Unit.assertValue(false, value)
end

Unit.assertNil = function(value)
    Unit.assertValue(nil, value)
end

Unit.runTests = function(tests, beforeTest, afterTest)
    for k, method in pairs(tests) do
        if beforeTest then beforeTest() end
        print(k, 'run')
        method()
        if afterTest then afterTest() end
        print(k, 'pass')
    end
end
return Unit
