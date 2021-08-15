local REPOSITOTY = "https://gitlab.com/lfreew1ndl/opencraftnetoriginal/-/raw/dev"

local shell = require("shell")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop-interface.lua /home/1.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/color.lua lib/color.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/Filesystem.lua lib/Filesystem.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/GUI.lua lib/GUI.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/image.lua lib/image.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/number.lua lib/number.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/Paths.lua lib/Paths.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/Screen.lua lib/Screen.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/shop/Text.lua lib/Text.lua")
