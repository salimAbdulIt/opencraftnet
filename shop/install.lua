local REPOSITOTY = "https://gitlab.com/lfreew1ndl/opencraftnetoriginal/-/raw/dev"

local shell = require("shell")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/forms.lua /home/lib/forms.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/shop.lua /home/1.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/shopService.lua lib/shopService.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/v2/database.lua lib/database.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/v2/libs/discord-logger.lua lib/dlog.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/v2/libs/utils.lua lib/utils.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/ItemUtils.lua lib/ItemUtils.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/oreExchanger.cfg /home/config/oreExchanger.cfg")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/exchanger.cfg /home/config/exchanger.cfg")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/sellShop.cfg /home/config/sellShop.cfg")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/buyShop.cfg /home/config/buyShop.cfg")

