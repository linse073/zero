local skynet = require "skynet"

local arg = ...

skynet.start(function()
    print(arg)
    skynet.exit()
end)
