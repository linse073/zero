local skynet = require "skynet"

skynet.start(function()
	skynet.error("Server start")
    -- debug service
    if not skynet.getenv("daemon") then
        skynet.newservice("console")
    end
	skynet.newservice("debug_console", skynet.getenv("debug_console"))

    -- service
	skynet.uniqueservice("cache")
    skynet.uniqueservice("dbmaster")
    skynet.uniqueservice("server_mgr")
    skynet.uniqueservice("routine")
    skynet.uniqueservice("role_mgr")
    skynet.uniqueservice("agent_mgr")

    local config = require(skynet.getenv("config"))
    for k, v in ipairs(config.db) do
        local dbslave = skynet.newservice("dbslave")
        skynet.call(dbslave, "lua", "open", v, "global")
    end
	local loginserver = skynet.newservice("login")
    for k, v in ipairs(config.game) do
        local server = skynet.newservice("server")
        skynet.call(server, "lua", "open", v, loginserver)
    end
    
    skynet.exit()
end)
