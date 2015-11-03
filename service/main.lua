local skynet = require "skynet"

skynet.start(function()
	local loginserver = skynet.newservice("login")
	local gate = skynet.newservice("gate", loginserver)

	skynet.call(gate, "lua", "open" , {
		port = 8888,
		maxclient = 64,
		servername = "sample",
	})
    
    skynet.exit()
end)
