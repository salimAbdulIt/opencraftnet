local component = require('component')
local drive = component.drive
require('Drive')

SSD = {}
function SSD:new(_fromSector, _numberOfSectors, _subSectorsNumber)
    local obj = {}

    function obj:init()
        self.fromSector = _fromSector
        self.sectorSize = 512
        self.subSectorsNumber = _subSectorsNumber
        self.sectorNumbers = _numberOfSectors

        self.drive = Drive:new(_fromSector, _numberOfSectors, _subSectorsNumber)
        self.subSectorSize = self.sectorSize / self.subSectorsNumber
    end

    function obj:writeIntoFile(fileName, data)

    end

    function obj:readFromFile(fileName, data)

    end

    function obj:findSectorByFileName(fileName)

    end

    function obj:associateFileNameWithSector(fileName, sector)

    end

    function obj:clearSSD()
        self.drive:clearDriver()
    end


    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
