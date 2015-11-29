local skynet = require "skynet"

skynet.start(function()
	skynet.error("Server start")
    -- debug service
    skynet.newservice("monitor", 9000)
	skynet.newservice("console")
	skynet.newservice("debug_console", 8000)

    -- service
	-- skynet.uniqueservice("protoloader")
    -- skynet.uniqueservice("dbmaster")
    -- skynet.uniqueservice("server_mgr")
    -- skynet.uniqueservice("routine")
    -- skynet.uniqueservice("role_mgr")
    -- skynet.uniqueservice("agent_mgr")

	-- local loginserver = skynet.newservice("login")
	-- local gate = skynet.newservice("gate", loginserver)
	-- skynet.call(gate, "lua", "open" , {
        -- address = "127.0.0.1",
	-- 	port = 8888,
	-- 	maxclient = 64,
	-- 	servername = "sample",
	-- })
	-- skynet.call(gate, "lua", "open" , {
        -- address = "127.0.0.1",
	-- 	port = 8889,
	-- 	maxclient = 64,
	-- 	servername = "sample",
	-- })

    -- local accountdb = skynet.newservice("dbslave")
    -- skynet.call(accountdb, "lua", "open", {
        -- host = "127.0.0.1",
        -- port = 6379,
        -- db = 0,
        -- name = "accountdb"
    -- })
    -- local userdb = skynet.newservice("dbslave")
    -- skynet.call(userdb, "lua", "open", {
        -- host = "127.0.0.1",
        -- port = 6379,
        -- db = 1,
        -- name = "userdb"
    -- })
    -- local namedb = skynet.newservice("dbslave")
    -- skynet.call(namedb, "lua", "open", {
        -- host = "127.0.0.1",
        -- port = 6379,
        -- db = 2,
        -- name = "namedb"
    -- })
    -- local tradedb = skynet.newservice("dbslave")
    -- skynet.call(tradedb, "lua", "open", {
        -- host = "127.0.0.1",
        -- port = 6379,
        -- db = 3,
        -- name = "tradedb"
    -- })
    -- local rankdb = skynet.newservice("dbslave")
    -- skynet.call(rankdb, "lua", "open", {
        -- host = "127.0.0.1",
        -- port = 6379,
        -- db = 4,
        -- name = "rankdb"
    -- })

    -- local sample = skynet.newservice("server")
    -- skynet.call(sample, "lua", "open", {
        -- serverid = 1,
        -- servername = "sample",
    -- })
    
    skynet.exit()
end)
