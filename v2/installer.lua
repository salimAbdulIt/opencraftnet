local REPOSITOTY = "https://gitlab.com/lfreew1ndl/opencraftnetoriginal/-/raw/1.7.10"

local shell = require("shell")
shell.execute("wget -fq " .. REPOSITOTY .. "/v2/launcher.lua /home/1.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/v2/libs/utils.lua /lib/utils.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/v2/config/settings.lua /lib/settings.lua")
shell.execute("edit /lib/settings.lua")
