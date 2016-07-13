local skynet = require "skynet"

local arg = {...}

skynet.start(function()
    for k, v in ipairs(arg) do
        print(v)
    end
    skynet.exit()
end)
