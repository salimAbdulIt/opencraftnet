local component = require('component')

local climatConfig = {[80] = {[40] = {["Hot"] = {["Damp"] = {["Coller"] = 0,["Heater"] = 3,["Conditioner"] = 3,["ConditionerType"] = "Water"},["Normal"] = {["Coller"] = 0,["Heater"] = 2,["Conditioner"] = 0,["ConditionerType"] = "Water"},["Arid"] = {["Coller"] = 0,["Heater"] = 1,["Conditioner"] = 1,["ConditionerType"] = "Lava"}},["Warm"] = {["Damp"] = {["Coller"] = 0,["Heater"] = 2,["Conditioner"] = 3,["ConditionerType"] = "Water"},["Normal"] = {["Coller"] = 0,["Heater"] = 1,["Conditioner"] = 0,["ConditionerType"] = "Water"},["Arid"] = {["Coller"] = 0,["Heater"] = 0,["Conditioner"] = 1,["ConditionerType"] = "Lava"}},["Normal"] = {["Damp"] = {["Coller"] = 0,["Heater"] = 0,["Conditioner"] = 3,["ConditionerType"] = "Water"},["Normal"] = {["Coller"] = 0,["Heater"] = 0,["Conditioner"] = 0,["ConditionerType"] = "Water"},["Arid"] = {["Coller"] = 1,["Heater"] = 0,["Conditioner"] = 1,["ConditionerType"] = "Lava"}},["Cold"] = {["Damp"] = {["Coller"] = 1,["Heater"] = 0,["Conditioner"] = 3,["ConditionerType"] = "Water"},["Normal"] = {["Coller"] = 3,["Heater"] = 0,["Conditioner"] = 0,["ConditionerType"] = "Water"},["Arid"] = {["Coller"] = 3,["Heater"] = 0,["Conditioner"] = 1,["ConditionerType"] = "Lava"}}}}}
local componentsConfig = {conditionerTransposers = {{ address = "25024e14-aa8c-4632-b6a7-06f1e7224f7c" },{ address = "d1eec36d-961a-42bb-ad89-741d08196d5c" },{ address = "8332c227-3078-4d95-9698-fa4311d06053" }},heatersRedstones = {{ address = "2f50d2e6-fca2-4b27-bfa4-404e820ebf1b" },{ address = "90b4287d-546b-4208-ba2e-0964330e0e44" },{ address = "2bbb6687-abca-461a-bcf0-1c0279a96794" }},collerRedstones = {{ address = "fe7f04d7-6f48-4010-8c04-718873aea0a6" },{ address = "b18ea5ab-d7ab-4eeb-97b9-1e497afe1e06" },{ address = "f855d65c-4b06-43dd-9578-a455d30b9608" }}}

local redstonesSide = 2
local transposerWaterSide = 2
local transposerLavaSide = 1
local transposerHiveSide = 3

local defaultClimat = {
    temperature = 80,
    humidity = 40
}

local currentClimatConfig = {
    ["Coller"] = 0,
    ["Heater"] = 2,
    ["Conditioner"] = 3,
    ["ConditionerType"] = "Water" -- Water|Lava
}

function initConponents()
    for i=1, #componentsConfig.conditionerTransposers do
        componentsConfig.conditionerTransposers[i].c = component.proxy(componentsConfig.conditionerTransposers[i].address)
    end
    for i=1, #componentsConfig.heatersRedstones do
        componentsConfig.heatersRedstones[i].c = component.proxy(componentsConfig.heatersRedstones[i].address)
    end
    for i=1, #componentsConfig.collerRedstones do
        componentsConfig.collerRedstones[i].c = component.proxy(componentsConfig.collerRedstones[i].address)
    end
end

function getClimatConfig()
    return climatConfig[defaultClimat.temperature][defaultClimat.humidity]
end

function setClimat(temperature, humidity)
    currentClimatConfig = getClimatConfig()[temperature][humidity]

    for i=1, 3 do
        if (currentClimatConfig.Coller >= i) then
            componentsConfig.collerRedstones[i].c.setOutput(redstonesSide, 1)
        else
            componentsConfig.collerRedstones[i].c.setOutput(redstonesSide, 0)
        end
    end

    for i=1, 3 do
        if (currentClimatConfig.Heater >= i) then
            componentsConfig.heatersRedstones[i].c.setOutput(redstonesSide, 1)
        else
            componentsConfig.heatersRedstones[i].c.setOutput(redstonesSide, 0)
        end
    end
end

function handleConditioners()
    for i=1, 3 do
        if (currentClimatConfig.Conditioner >= i) then
            local fluidInConditioner = componentsConfig.conditionerTransposers[i].c.getFluidInTank(transposerHiveSide)[1].amount
            local desiredFluidCount = (currentClimatConfig.ConditionerType == "Water") and 200 or 40
            if ((desiredFluidCount/2) > fluidInConditioner) then
                local fluidSide = (currentClimatConfig.ConditionerType == "Water") and transposerWaterSide or transposerLavaSide
                componentsConfig.conditionerTransposers[i].c.transferFluid(fluidSide, transposerHiveSide, desiredFluidCount)
            end
        end
    end
end
initConponents()
setClimat("Hot", "Damp")
while true do
    os.sleep(1)
    handleConditioners()
end
