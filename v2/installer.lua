local REPOSITOTY = "https://gitlab.com/lfreew1ndl/opencraftnetoriginal/-/raw/dev"

local shell = require("shell")
shell.execute("wget -fq " .. REPOSITOTY .. "/v2/launcher.lua /home/1.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/v2/libs/utils.lua /lib/utils.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/v2/config/settings.lua /lib/settings.lua")
shell.execute("edit /lib/settings.lua")


shell.execute("wget -fq " .. REPOSITOTY .. "/shop/oreExchanger.cfg /home/config/oreExchanger.cfg")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/sellShop.cfg /home/config/sellShop.cfg")
