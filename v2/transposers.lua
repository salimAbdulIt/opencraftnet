local component = require('component')
local serial = require('serialization')
local shell = require('shell')
local io = require('io')
local fs = require("filesystem")

Transposers = {}
function Transposers:new()
    local obj = {}

    function obj:init()
        self.transposerAddresses = {}
        self.storageAddresses = {} -- todo add "" as a storage
        self:customizeStorages()
    end

    obj.revercedAddresses = { [0] = 1, 0, 3, 2, 5, 4 }
    function obj:reverceAddress(address)
        return self.revercedAddresses[address]
    end

    function obj:customizeStorages()
        self.tempTransposers = {}
        self.storageAddresses = {}
        for k, v in pairs(component.list('transposer')) do
            self.tempTransposers[k] = component.proxy(k)
        end
        self:customizeStoragesRec("", -1)
    end

    function obj:customizeStoragesRec(address, lastOutputTransposer)
        local returnedValue = false
        for inputSide = 0, 5 do
            for k, tcomponent in pairs(self.tempTransposers) do
                local item = tcomponent.getStackInSlot(inputSide, 1)
                if (item and item.label == 'Durex77'
                        and lastOutputTransposer ~= tcomponent.address) then
                    self.transposerAddresses[address] = {}
                    self.transposerAddresses[address].transposer = tcomponent
                    self.transposerAddresses[address].inputSide = inputSide
                    if (address == "") then
                        local address1 = {}
                        address1.address = ""
                        address1.side = 1
                        self.storageAddresses[address1] = {}
                        self.storageAddresses[address1].address = ""
                        self.storageAddresses[address1].outputSide = 1
                        self.storageAddresses[address1].inputSide = 0
                        self.storageAddresses[address1].isUsedInTransfers = false
                        self.storageAddresses[address1].name = self.transposerAddresses[""].transposer.getInventoryName(1)
                        self.storageAddresses[address1].size = self.transposerAddresses[""].transposer.getInventorySize(outputSide)
                    end
                    for outputSide = 0, 5 do
                        if (inputSide ~= outputSide) then
                            local outputSideInventorySize = self.transposerAddresses[address].transposer.getInventorySize(outputSide)
                            if (outputSideInventorySize) then
                                -- found storage
                                returnedValue = true
                                local address1 = {}
                                address1.address = address
                                address1.side = outputSide
                                self.storageAddresses[address1] = {}
                                self.storageAddresses[address1].address = address
                                self.storageAddresses[address1].outputSide = outputSide
                                self.storageAddresses[address1].inputSide = inputSide
                                self.storageAddresses[address1].isUsedInTransfers = false
                                self.storageAddresses[address1].name = self.transposerAddresses[address].transposer.getInventoryName(outputSide)
                                self.storageAddresses[address1].size = outputSideInventorySize
                                if (self.transposerAddresses[address].transposer.transferItem(inputSide, outputSide, 64, 1, 1) ~= 0) then
                                    if (self:customizeStoragesRec(address .. outputSide, self.transposerAddresses[address].transposer.address)) then
                                        self.storageAddresses[address1].isUsedInTransfers = true
                                    end
                                    self.transposerAddresses[address].transposer.transferItem(outputSide, inputSide, 64, 1, 1)
                                end
                            end
                        end
                    end
                end
            end
        end
        return returnedValue
    end

    function obj:getAllTransposers()
        return self.transposerAddresses
    end

    function obj:getAllStorages()
        return self.storageAddresses
    end

    function obj:transferItemOutside(fromAddress, fromSide, fromSlot, count, stopLevel, toSlot)
        local isLastMove = #fromAddress > stopLevel + 1
        local storage = self.transposerAddresses[fromAddress]
        storage.transposer.transferItem(fromSide, storage.inputSide, count, fromSlot, isLastMove and toSlot or 1)

        if (isLastMove) then
            self:transferItemOutside(fromAddress:sub(1, #fromAddress - 1), tonumber(fromAddress:sub(#fromAddress, #fromAddress)), 1, count, stopLevel)
        end
    end

    function obj:transferItemInside(toAddress, toSide, toSlot, fromAddress, fromSide, fromSlot, count)
        local storage = self.transposerAddresses[fromAddress]
        local tempFromSide = fromSide or storage.inputSide
        if (fromAddress == toAddress) then
            if (toSlot) then
                storage.transposer.transferItem(tempFromSide, toSide, count, fromSlot, toSlot)
            else
                storage.transposer.transferItem(tempFromSide, toSide, count, fromSlot)
            end
        else
            local tempToSide = tonumber(toAddress:sub(#fromAddress + 1, #fromAddress + 1))
            storage.transposer.transferItem(tempFromSide, tempToSide, count, fromSlot, 1)
            return self:transferItemInside(toAddress, toSide, toSlot, fromAddress .. tempToSide, nil, 1, count)
        end
    end

    function obj:transferItem(fromAddress, fromSide, fromSlot, toAddress, toSide, toSlot, count)
        local sameAddressLetters = 0
        for i = 1, string.len(fromAddress) do
            if (not (fromAddress:sub(i, i) == toAddress:sub(i, i))) then
                break
            end
            sameAddressLetters = i
        end
        local tempFromSide = fromSide
        local tempFromSlot = fromSlot
        local someCheck = (#toAddress == sameAddressLetters and tostring(self.transposerAddresses[toAddress].side) == fromAddress:sub(sameAddressLetters+1,sameAddressLetters+1))
        if (#fromAddress > sameAddressLetters) then
            self:transferItemOutside(fromAddress, fromSide, fromSlot, count, sameAddressLetters, someCheck and toSlot or 1)
            tempFromSide = tonumber(fromAddress:sub(sameAddressLetters + 1, sameAddressLetters + 1))
            tempFromSlot = 1
        end
        if (not someCheck) then
            self:transferItemInside(toAddress, toSide, toSlot, toAddress:sub(1, sameAddressLetters), tempFromSide, tempFromSlot, count)
        end
    end

    function obj:getAllStacks(address, side)
        if (address) then
            return self.transposerAddresses[address].transposer.getAllStacks(side)
        else
        end
    end

    function obj:store(address, side, slot, dbAddress, dbSlot)
        return self.transposerAddresses[address].transposer.store(side, slot, dbAddress, dbSlot)
    end

    function obj:compareStackToDatabase(address, side, slot, dbAddress, dbSlot, checkNBT)
        return self.transposerAddresses[address].transposer.compareStackToDatabase(side, slot, dbAddress, dbSlot, checkNBT)
    end

    function obj:getInventorySize(address, side)
        return self.transposerAddresses[address].transposer.getInventorySize(side)
    end

    function obj:getSlotMaxStackSize(address, side, slot)
        return self.transposerAddresses[address].transposer.getSlotMaxStackSize(side, slot)
    end

    function obj:getStackInSlot(address, side, slot)
        return self.transposerAddresses[address].transposer.getStackInSlot(side, slot)
    end

    function obj:areStacksEquivalent(addressA, sideA, slotA, addressB, sideB, slotB)
        if (addressA == addressB and sideA == sideB) then
            return self.transposerAddresses[addressA].transposer.areStacksEquivalent(sideA, slotA, slotB)
        else
            --todo write the logic with the database or check by my own
        end
    end

    function obj:compareStacks(addressA, sideA, slotA, addressB, sideB, slotB, checkNBT)
        if (addressA == addressB and sideA == sideB) then
            return self.transposerAddresses[addressA].transposer.compareStacks(sideA, slotA, slotB, checkNBT)
        else
            --todo write the logic with the database or check by my own
        end
    end

    setmetatable(obj, self)
    obj:init()
    self.__index = self; return obj
end
