local REPOSITOTY = "https://raw.githubusercontent.com/salimAbdulIt/opencraftnet/1.7.10/storage"

local shell = require("shell")
shell.execute("wget -fq " .. REPOSITOTY .. "/launcher.lua /home/1.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/libs/utils.lua /lib/utils.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/config/settings.lua /lib/settings.lua")
shell.execute("edit /lib/settings.lua")
