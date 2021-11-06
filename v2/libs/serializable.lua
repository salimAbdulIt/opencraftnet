local filesystem = require("filesystem")
local computer = require("computer")

local utils = {}

function utils.freeMemory()
    local result = 0
    for i = 1, 10 do
        result = math.max(result, computer.freeMemory())
        os.sleep(0)
    end
    return result
end

local serializable = {}

-- minimum bytes to write at once, power of two - 16 wiggle room for elements in the table res[i] increasing varying amounts between flushes
serializable.flushSize = (1 << 15) - 16
-- how many bytes to read at once, read maximum allowed by the stream
serializable.readSize = math.huge

function serializable.tryConcat(t, i, j)
    i = i or 1
    j = j or #t

    local result, str = pcall(table.concat, t, "", i, j)
    if result then
        return str
    elseif string.find(str, "not enough memory") then
        -- divide and conquer
        -- if not enough memory we split the table into two parts and try to concat those separately
        local mid = (i + j) // 2
        local str1 = serializable.tryConcat(t, i, mid)
        local str2 = serializable.tryConcat(t, mid + 1, j)
        result, str = pcall(table.concat, {str1, str2}) -- if this fails we can't possibly hold the resulting string
        if result then
            return str
        else
            error(err) -- catch and rethrow error to prevent OpenOS' process library from crashing
        end
    else
        error(str) -- catch and rethrow error to prevent OpenOS' process library from crashing
    end
end

function serializable._serialize(tab, stream, flushSize, res, i, level)
    assert(type(tab) == "table", "1st argument must be a table")
    assert((type(stream) == "table" or type(stream) == "userdata") and stream.write ~= nil, "2nd argument must be an open file stream")
    flushSize = flushSize or serializable.flushSize
    res = res or {}
    i = i or 1
    level = level or 0

    res[i] = "{"
    i = i + 1

    for k, v in pairs(tab) do
        local tkey = type(k)
        local tval = type(v)

        if tkey == "string" then
            -- wrap in [""] for extra safety
            res[i] = "[\"" .. k .. "\"]"
            i = i + 1
        elseif tkey == "number" then
            res[i] = "[" .. tostring(k) .. "]"
            i = i + 1
        elseif tkey == "boolean" then
            res[i] = tostring(k)
            i = i + 1
        elseif tkey == "table" then
            -- only call recursively for tables to avoid functionc call overhead
            res, i = serializable._serialize(k, stream, flushSize, res, i, level + 1)
        else
            error(string.format("Tried serializing value of %s type", tkey))
        end

        res[i] = "="
        i = i + 1

        if tval == "string" then
            res[i] = "\"" .. v .. "\""
            i = i + 1
        elseif tval == "number" then
            -- no need to call tostring, table.concat will convert it to string
            res[i] = v
            i = i + 1
        elseif tval == "boolean" then
            res[i] = tostring(v)
            i = i + 1
        elseif tval == "table" then
            -- only call recursively for tables to avoid functionc call overhead
            res, i = serializable._serialize(v, stream, flushSize, res, i, level + 1)
        else
            error(string.format("Tried serializing value of %s type", tval))
        end

        res[i] = ","
        i = i + 1

        if i >= flushSize then
            stream:write(serializable.tryConcat(res))
            res = {}
            i = 1
        end
    end

    -- flush any remaining elements
    res[i] = "}"
    i = i + 1
    if level == 0 then
        stream:write(serializable.tryConcat(res))
    else
        return res, i
    end
end

-- safe wrapper around main serialization function which halves
-- flushSize if it's too large for one serialization pass to handle
function serializable.serialize(tab, stream, flushSize)
    local ok = false
    local flushSize = flushSize or serializable.flushSize
    while not ok do
        ok = pcall(serializable._serialize, tab, stream, flushSize)
        if not ok then
            utils.freeMemory()
            flushSize = flushSize // 2
        end
    end
end

-- wrapper for serialization.serialize which accepts filename instead of a stream
function serializable.serializeToFile(tab, filename, flushSize)
    -- using filesystem.open instead of io.open because it's not buffered
    -- and buffered streams often throw OOM errors
    local handle = filesystem.open(filename, "w")
    serializable.serialize(tab, handle, flushSize)
    handle:close()
end

function serializable.unserialize(stream, readSize)
    assert((type(stream) == "table" or type(stream) == "userdata") and stream.read ~= nil, "1st argument must be an open file stream")

    local buf = {"return "}
    local sum = 0
    local readSize = readSize or serializable.readSize
    repeat
        local read = stream:read(readSize)
        buf[#buf+1] = read
        sum = sum + (read and #read or 0)
        --print(string.format("Read %d chunks, %d bytes", #buf, sum))
    until read == nil

    -- use a function to get chunk pieces instead of trying to concat the result
    -- we need to use this function returning already loaded data instead of loading inside
    -- of it because we have pretty much guaranteed attempting-to-cross-C-call-boundary
    -- errors otherwise (because stream:read takes too much time and machine.lua will
    -- inevitably try to yield while we're reading causing the error)
    local cnt = 0
    local function getChunk()
        cnt = cnt + 1
        return buf[cnt]
    end

    local f, err = load(getChunk)
    -- take care to garbage collect the loaded strings before attempting to run the loaded function
    buf = nil
    utils.freeMemory()
    if f then
        local ok, res = pcall(f)
        -- garbage collect the function which returned deserialized table as we only care about the table itself
        f = nil
        utils.freeMemory()
        if ok then
            return res
        else
            error(res) -- catch and rethrow error to prevent OpenOS' process library from crashing
        end
    else
        error(err) -- catch and rethrow error to prevent OpenOS' process library from crashing
    end
end

-- wrapper for serializable.unserialize which accepts filename instead of a stream
function serializable.unserializeFromFile(filename, readSize)
    -- using filesystem.open instead of io.open because it's not buffered
    -- and buffered streams often throw OOM errors
    local handle = filesystem.open(filename, "r")
    local res = serializable.unserialize(handle, readSize)
    handle:close()
    return res
end

return serializable
