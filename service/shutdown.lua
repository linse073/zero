local skynet = require "skynet"

skynet.start(function()
    local server_mgr = skynet.queryservice("server_mgr")
    skynet.call(server_mgr, "lua", "shutdown")
    local explore_mgr = skynet.queryservice("explore_mgr")
    skynet.call(explore_mgr, "lua", "shutdown")
    -- TODO: save server shutdown time
    skynet.error("shutdown finish.")
    skynet.exit()
end)
