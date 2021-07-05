local REPOSITOTY = "https://gitlab.com/lfreew1ndl/opencraftnetoriginal/-/raw/dev"

local shell = require("shell")
shell.execute("wget -fq " .. REPOSITOTY .. "/v2/thaumcraft/autofill.lua /home/1.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/v2/libs/utils.lua /lib/utils.lua")
shell.execute("wget -fq " .. REPOSITOTY .. "/v2/libs/lists.lua /lib/lists.lua")
