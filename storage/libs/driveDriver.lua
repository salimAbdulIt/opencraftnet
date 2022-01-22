local component = require('component')
local drive = component.drive
local ser = require('serialization')


local FreeSubSectorIterator = {}
function FreeSubSectorIterator:new(parent)
    local obj = {}
    function obj:init()

    end

    function obj:next()
        self.sector = nil
        parent.freeSubSectorNumber = self.nextFreeSlotNumber
        self.nextFreeSlotNumber = nil
        self.sectorNumber = nil
        self.sectorsSubSectorNumber = nil
    end

    function obj:close()
        self:next()
    end

    function obj:getSectorNumber()
        if (not self.sectorNumber) then
            local sectorNumber, sectorsSubSectorNumber = parent:parseSubSectorNumber(parent.freeSubSectorNumber)
            self.sectorNumber = sectorNumber
            self.sectorsSubSectorNumber = sectorsSubSectorNumber
        end
        return self.sectorNumber
    end

    function obj:getSubSectorNumber()
        if (not self.sectorsSubSectorNumber) then
            self:getSectorNumber()
        end
        return self.sectorsSubSectorNumber
    end

    function obj:getSectorsSubSectorNumber()
        return parent.freeSubSectorNumber
    end

    function obj:getNextSlot()
        if (not self.nextFreeSlotNumber) then
              self:getSector()
        end
        return self.nextFreeSlotNumber
    end

    function obj:getSector()
        if (not self.sector) then
            local nextFreeSlotNumber, flag, wholeSector = parent:readFromSubSector(parent.freeSubSectorNumber)
            self.sector = wholeSector
            self.nextFreeSlotNumber = nextFreeSlotNumber
        end
        return self.sector
    end

    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end

local SubSectorIterator = {}
function SubSectorIterator:new(parent)
    local obj = {}
    function obj:init()

    end

    function obj:next()
        self.sector = nil
        parent.freeSubSectorNumber = self:getNextSlot()
        self.nextFreeSlotNumber = nil
        self.sectorNumber = nil
        self.sectorsSubSectorNumber = nil
    end

    function obj:close()
        self:next()
    end

    function obj:getSectorNumber()
        if (not self.sectorNumber) then
            local sectorNumber, sectorsSubSectorNumber = parent:parseSubSectorNumber(parent.freeSubSectorNumber)
            self.sectorNumber = sectorNumber
            self.sectorsSubSectorNumber = sectorsSubSectorNumber
        end
        return self.sectorNumber
    end

    function obj:getSubSectorNumber()
        if (not self.sectorsSubSectorNumber) then
            self:getSectorNumber()
        end
        return self.sectorsSubSectorNumber
    end

    function obj:getSectorsSubSectorNumber()
        return parent.freeSubSectorNumber
    end

    function obj:getNextSlot()
        if (not self.nextFreeSlotNumber) then
            self:getSector()
        end
        return self.nextFreeSlotNumber
    end

    function obj:getSector()
        if (not self.sector) then
            local nextFreeSlotNumber, flag, wholeSector = parent:readFromSubSector(parent.freeSubSectorNumber)
            self.sector = wholeSector
            self.nextFreeSlotNumber = nextFreeSlotNumber
        end
        return self.sector
    end

    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end


Drive = {}
function Drive:new(_fromSector, _numberOfSectors, _subSectorsNumber)
    local obj = {}

    function obj:createFreeSubSectorIterator()
        return FreeSubSectorIterator:new(self)
    end

    function obj:init()
        self.metadataSubSector = ((_fromSector - 1) * _numberOfSectors) + 1
        self.sectorSize = 512
        self.subSectorsNumber = _subSectorsNumber
        self.sectorNumbers = _numberOfSectors
        self.fromSubSector = self.metadataSubSector + 1
        self.freeSubSectorNumber = self.metadataSubSector + 1

        self.freeSubSectorIterator = self:createFreeSubSectorIterator()
        self.subSectorSize = self.sectorSize / self.subSectorsNumber

        local parsedData, flag, wholeSector = self:readFromSubSector(self.metadataSubSector)
        if (flag == 2) then
            local metaData = ser:unserialize(parsedData)
            self.freeSubSectorNumber = metaData[1]
            self:writeToSubSector(self.freeSubSectorNumber, "3" .. (metaData[2]) .. '$', wholeSector, true)
        else
            self:clearDriver()
        end
    end

    function obj:parseSubSectorNumber(subSectorNumber)
        local sectorNumber = math.floor(subSectorNumber / self.subSectorsNumber) + 1
        local sectorsSubSector = subSectorNumber % self.subSectorsNumber
        return sectorNumber, sectorsSubSector
    end

    function obj:parseMetaNumber(data, startIndex)
        local metaData = ''
        local i = startIndex
        while true do
            local char = data:sub(i, i)
            if char == '$' then
                i = i + 1
                break
            else
                metaData = metaData .. char
            end
            i = i + 1
        end
        return tonumber(metaData), i
    end

    function obj:readFromSubSector(subSectorNumber)
        local sectorNumber, sectorsSubSector = self:parseSubSectorNumber(subSectorNumber)
        local data = drive.readSector(sectorNumber)

        local indexOfTheFlag = 1 + (sectorsSubSector * self.subSectorSize)
        local flag = data:sub(indexOfTheFlag, indexOfTheFlag)
        local parsedData
        if (flag == '0') then
            local dataSize, startIndex = self:parseMetaNumber(data, indexOfTheFlag)
            parsedData = data:sub(startIndex, startIndex + dataSize - 1)
        elseif (flag == '1') then
            local nextSubSectorNumber, startIndex = self:parseMetaNumber(data, indexOfTheFlag)
            local nextPartOfParsedData, nextFlag = self:readSubSector(nextSubSectorNumber)
            if (nextFlag == '2') then
                error("Corrupted data. Free slot instead of data")
            end
            parsedData = data:sub(startIndex, startIndex + (nextSubSectorNumber:len() + 2) * sectorsSubSector) .. nextPartOfParsedData
        elseif (flag == '2') then
            local nextFreeSubSectorNumber = self:parseMetaNumber(data, indexOfTheFlag)
            return nextFreeSubSectorNumber, flag, data
        else
            return flag, 3, data
        end

        return parsedData, flag, data
    end

    function obj:writeInTheFreePlace(newData)
        self:writeToSubSectors(self.freeSubSectorIterator, newData)
    end


    function obj:writeToSubSectors(subSectorsIterator, newData, ignoreMeta)
        local sectorNumber =  subSectorsIterator:getSectorNumber()
        local sectorsSubSectorNumber = subSectorsIterator:getSectorsSubSectorNumber()

        local newDataLen = newData:len()
        local nextSlot = subSectorsIterator:getNextSlot()
        if ((ignoreMeta and newDataLen or (newDataLen + tostring(nextSlot):len() + 2)) > self.subSectorSize) then
            local data = subSectorsIterator:getSector()
            local newDataWithMeta = ignoreMeta and newData or ('1' .. nextSlot .. "$" .. newData) --todo investigate
            local subSectorEnd = self.subSectorSize * (sectorsSubSectorNumber + 1) - (self.subSectorSize - newDataWithMeta:len())
            data = data:sub(1, self.subSectorSize * sectorsSubSectorNumber) .. newDataWithMeta:sub(1, self.subSectorSize) .. data:sub(subSectorEnd + 1, self.sectorSize)
            drive.writeSector(sectorNumber, data)

            subSectorsIterator:next()
            self:writeToSubSector(subSectorsIterator, newDataWithMeta:sub(self.subSectorSize + 1))
        else
            local data = subSectorsIterator:getSector()
            local newDataWithMeta = ignoreMeta and newData or ('1' .. nextSlot .. "$" .. newData)

            local subSectorEnd = self.subSectorSize * (sectorsSubSectorNumber + 1) - (self.subSectorSize - newDataWithMeta:len())
            data = data:sub(1, self.subSectorSize * sectorsSubSectorNumber) .. newDataWithMeta .. data:sub(subSectorEnd + 1, self.sectorSize)
            drive.writeSector(sectorNumber, data)
            subSectorsIterator:close()
        end
    end

    function obj:getFreeSubSector()
        if (not self.freeSubSectorNumber) then
            error("Not enough space")
        end
        return self.freeSubSectorNumber
    end

    function obj:pollFreeSubSector()
        if (not self.freeSubSectorNumber) then
            error("Not enough space")
        end
        local freeSubSectorNumber, flag, wholeSector = self:readFromSubSector(self.freeSubSectorNumber)
        if (flag ~= '2') then
            error("Corrupted data. Data instead of free slot")
        end
        local oldFreeSlotNumber = self.freeSubSectorNumber
        self.freeSubSectorNumber = freeSubSectorNumber
        self:writeToSubSector(self.metadataSubSector, "3" .. (metaData[2]) .. '$', true)
        return oldFreeSlotNumber, wholeSector
    end

    function obj:clearDriver()
        local lastSubSector = self.fromSubSector + self.sectorNumbers * self.subSectorsNumber
        for i = self.fromSubSector, lastSubSector - 1 do
            self:writeToSubSector(i, "2" .. (i + 1) .. '$', true)
        end
        self:writeToSubSector(lastSubSector, "2" .. 0 .. '$', true)
        self.freeSubSectorNumber = 1
    end


    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
