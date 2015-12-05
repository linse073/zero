local skynet = require "skynet"

skynet.start(function()
    local server_mgr = skynet.queryservice("server_mgr")
    skynet.call(server_mgr, "lua", "shutdown")
end)
