local shell = require("shell")
local fs = require("filesystem")
local alwaysUpdate = true
local proxy = "http://durex77.pythonanywhere.com/krov/proxy?url="

if not fs.exists("/lib/db.lua") or alwaysUpdate then -- todo change to for
    if fs.exists("/lib/db.lua") then
        shell.execute("rm /lib/db.lua")
    end
    shell.execute("wget ".. proxy .. "https://gitlab.com/lfreew1ndl/opencraftnetoriginal/-/raw/dev/db.lua /lib/db.lua")
end

if not fs.exists("/lib/durexdb.lua") or alwaysUpdate then
    if fs.exists("/lib/durexdb.lua") then
        shell.execute("rm /lib/durexdb.lua")
    end
    shell.execute("wget ".. proxy .. "https://gitlab.com/lfreew1ndl/opencraftnetoriginal/-/raw/dev/durexdb.lua /lib/durexdb.lua")
end

if not fs.exists("/lib/inMemoryDb.lua") or alwaysUpdate then
    if fs.exists("/lib/inMemoryDb.lua") then
        shell.execute("rm /lib/inMemoryDb.lua")
    end
    shell.execute("wget ".. proxy .. "https://gitlab.com/lfreew1ndl/opencraftnetoriginal/-/raw/dev/inMemoryDb.lua /lib/inMemoryDb.lua")
end

if not fs.exists("/lib/serial.lua") or alwaysUpdate then
    if fs.exists("/lib/serial.lua") then
        shell.execute("rm /lib/serial.lua")
    end
    shell.execute("wget ".. proxy .. "https://gitlab.com/lfreew1ndl/opencraftnetoriginal/-/raw/dev/serial.lua /lib/serial.lua")
end


if not fs.exists("/home/db") then
    shell.execute("mkdir db")
end

if not fs.exists("/home/db/start.lua") or alwaysUpdate then
    if fs.exists("/home/db/start.lua") then
        shell.execute("rm /home/db/start.lua")
    end
    shell.execute("wget ".. proxy .. "https://gitlab.com/lfreew1ndl/opencraftnetoriginal/-/raw/dev/start.lua /home/db/start.lua")
end


if not fs.exists("/home/db/int.lua") or alwaysUpdate then
    if fs.exists("/home/db/int.lua") then
        shell.execute("rm /home/db/int.lua")
    end
    shell.execute("wget ".. proxy .. "https://gitlab.com/lfreew1ndl/opencraftnetoriginal/-/raw/dev/int.lua /home/db/int.lua")
end
