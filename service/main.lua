local skynet = require "skynet"
local snax = require "snax"

skynet.start(function()
	local loginserver = skynet.newservice("login")
	local gate = skynet.newservice("gate", loginserver)
	skynet.call(gate, "lua", "open" , {
		port = 8888,
		maxclient = 64,
		servername = "sample",
	})

    local dbmaster = snax.uniqueservice("dbmaster")
    local accountdb = snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6379,
        db = 0,
        name = "account"
    })
    local userdb = snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6380,
        db = 0,
        name = "user"
    })
    local tradedb = snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6381,
        db = 0,
        name = "trade"
    })
    
    skynet.exit()
end)
