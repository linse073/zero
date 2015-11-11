local skynet = require "skynet"
local snax = require "snax"

skynet.start(function()
	print("Server start")
	skynet.uniqueservice("proto.protoloader")
	skynet.newservice("console")
	skynet.newservice("debug_console", 8000)

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
        port = 6380,
        db = 0,
        name = "userdb"
    })
    snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6381,
        db = 0,
        name = "tradedb"
    })

    snax.uniqueservice("message")
    
    skynet.exit()
end)
