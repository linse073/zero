local skynet = require "skynet"
local snax = require "snax"

skynet.start(function()
	print("Server start")
	skynet.newservice("console")
	skynet.newservice("debug_console", 8000)
	skynet.uniqueservice("proto.protoloader")

	local loginserver = skynet.newservice("login")
	local gate = skynet.newservice("gate", loginserver)
	skynet.call(gate, "lua", "open" , {
		port = 8888,
		maxclient = 64,
		servername = "sample",
	})

    snax.uniqueservice("dbmaster")
    snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6379,
        db = 0,
        name = "accountdb"
    })
    snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6379,
        db = 1,
        name = "userdb"
    })
    snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6379,
        db = 2,
        name = "namedb"
    })
    snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6379,
        db = 3,
        name = "tradedb"
    })
    snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6379,
        db = 4,
        name = "rankdb"
    })

    snax.uniqueservice("server_mgr")
    snax.newservice("server", {
        serverid = 1,
    })

    snax.uniqueservice("routine")
    snax.uniqueservice("role_mgr")
    snax.uniqueservice("data_mgr")
    
    skynet.exit()
end)
