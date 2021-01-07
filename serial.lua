local io = require('io')


Serial = {}
function Serial:new()

    local obj = {}

    function obj:writeLine(file, line)
        file:write(line .. '\n')
    end

    function obj:readLine(file)
        return file:read('*l')
    end

    function obj:save(filePath, value)
        local file = io.open(filePath, 'w')
        self:saveUnknownType(file, nil, value)
        file:close()
    end

    function obj:readUnknownType(file, value)
        local line = self:readLine(file);
        if (line == '{') then
            local result = {}
            self:readUnknownType(file, result)
            return result
        elseif (line == '}') then

        else
            local words = {}
            for word in string.gmatch(line, '([^=]+)') do
                table.insert(words, word)
            end
            local keyToSave

            if (string.sub(words[1], 1, 1) == '[') then
                keyToSave = tonumber(string.sub(words[1], 2, string.len(words[1]) - 1))
            else
                keyToSave = words[1]
            end

            if (words[2] == '{') then
                value[keyToSave] = {}
                self:readUnknownType(file, value[keyToSave])
                self:readUnknownType(file, value)
            elseif (words[2] == '}') then
                return
            else
                if (string.sub(words[2], 1, 1) == '"') then
                    value[keyToSave] = string.sub(words[2], 2, string.len(words[2]) - 1)
                else
                    value[keyToSave] = tonumber(words[2])
                end
                self:readUnknownType(file, value)
            end
        end
    end

    function obj:read(filePath)
        local file = io.open(filePath, 'r')
        local result = self:readUnknownType(file, nil)
        file:close()
        return result
    end

    function obj:saveUnknownType(file, key, value)
        local valueType = type(value)
        print(valueType)
        if (valueType == 'table') then
            self:saveTable(file, key, value)
        elseif (valueType == 'number') then
            self:saveNumber(file, key, value)
        elseif (valueType == 'string') then
            self:saveString(file, key, value)
        end
    end

    function obj:saveTable(file, key, value)
        if (key) then
            self:writeLine(file, key .. '={')
        else
            self:writeLine(file, '{')
        end
        for k, v in pairs(value) do
            if (type(k) == 'number') then
                k = '[' .. k .. ']'
            end
            self:saveUnknownType(file, k, v)
        end
        self:writeLine(file, '}')
    end

    function obj:saveNumber(file, key, value)
        if (key) then
            self:writeLine(file, key .. '=' .. value)
        else
            self:writeLine(file, value .. '')
        end
    end

    function obj:saveString(file, key, value)
        if (key) then
            self:writeLine(file, key .. '="' .. value .. '"')
        else
            self:writeLine(file, '"' .. value .. '"')
        end
    end

    setmetatable(obj, self)
    self.__index = self; return obj
end

return Serial:new()
