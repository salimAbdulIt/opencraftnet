local fs = require('filesystem')
local shell = require('shell')
local unit = require('unit')
local utils = require('utils')

require('driveDriver')

local Tests = {}
local Drive = Drive:new(1,20,4)
function beforeTest()
    Drive:clearDrive()
end

function Tests:clearDrive()

end

function Tests:saveMetadata()

end

function Tests:saveHugeMetadata()

end

function Tests:loadMetadata()

end

function Tests:loadHugeMetadata()

end

function Tests:saveDataInFreeSlot()

end

function Tests:saveDatainHugeBusySector()

end

function Tests:saveHugeDataInSmallBusySector()

end

function Tests:loadData()

end

function Tests:loadHugeData()

end




unit.runTests(Tests, beforeTest)
