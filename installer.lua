local shell = require("shell")
local fs = require("filesystem")
local alwaysUpdate = true
if not fs.exists("/lib/db.lua") or alwaysUpdate then
    if fs.exists("/lib/db.lua") then
        shell.execute("rm /lib/db.lua")
    end
    shell.execute("wget https://gitlab.com/lfreew1ndl/opencraftnetoriginal/raw/master/db.lua /lib/db.lua")
end

if not fs.exists("/lib/durexdb.lua") or alwaysUpdate then
    if fs.exists("/lib/durexdb.lua") then
        shell.execute("rm /lib/durexdb.lua")
    end
    shell.execute("wget https://gitlab.com/lfreew1ndl/opencraftnetoriginal/raw/master/durexdb.lua /lib/durexdb.lua")
end

if not fs.exists("/lib/inMemory.lua") or alwaysUpdate then
    if fs.exists("/lib/inMemory.lua") then
        shell.execute("rm /lib/inMemory.lua")
    end
    shell.execute("wget https://gitlab.com/lfreew1ndl/opencraftnetoriginal/raw/master/durexdb.lua /lib/inMemory.lua")
end


if not fs.exists("/home/db") then
    shell.execute("mkdir db")
end

if not fs.exists("/home/db/start.lua") or alwaysUpdate then
    if fs.exists("/home/db/start.lua") then
        shell.execute("rm /home/db/start.lua")
    end
    shell.execute("wget https://gitlab.com/lfreew1ndl/opencraftnetoriginal/raw/master/start.lua /home/db/start.lua")
end


if not fs.exists("/home/db/int.lua") or alwaysUpdate then
    if fs.exists("/home/db/int.lua") then
        shell.execute("rm /home/db/int.lua")
    end
    shell.execute("wget https://gitlab.com/lfreew1ndl/opencraftnetoriginal/raw/master/int.lua /home/db/int.lua")
end
