local event = require("event")
local shell = require("shell")
local unicode = require("unicode")
local settings = require("settings")
local computer = require('computer')
local fs = require('filesystem')
local utils = require('utils')

local requiredDirectories = {}

REPOSITORY = settings.REPOSITORY

local libs = {
    {
        url = REPOSITORY .. "/v2/config/settings.lua",
        path = "/lib/settings.lua"
    },
    {
        url = REPOSITORY .. "/v2/libs/utils.lua",
        path = "/lib/utils.lua"
    },
    {
        url = REPOSITORY .. "/v2/database.lua",
        path = "/lib/database.lua"
    },
    {
        url = REPOSITORY .. "/v2/storage-system.lua",
        path = "/lib/storage-system.lua"
    },
    {
        url = REPOSITORY .. "/v2/storage-interface.lua",
        path = "/home/storage-interface.lua"
    },
    {
        url = REPOSITORY .. "/v2/transposers.lua",
        path = "/lib/transposers.lua"
    }
}

local function initLauncher()
    for i = 1, #requiredDirectories do
        shell.execute("md " .. requiredDirectories[i])
    end
    for i = 1, #libs do
        if fs.exists(libs[i].path) then
            shell.execute("rm " .. libs[i].path)
        end
        utils.downloadFile(libs[i].url, libs[i].path)
    end
end

initLauncher()
