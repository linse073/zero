local skynet = require "skynet"

local assert = assert
local string = string

local server_list = {}

local CMD = {}

function CMD.register(servername, address)
    assert(not server_list[servername], string.format("Already register server %s.", servername))
    server_list[servername] = address
end

function CMD.shutdown()
    for k, v in pairs(server_list) do
        skynet.call(v, "lua", "shutdown")
    end
end

function CMD.get(servername)
    return assert(server_list[servername], string.format("No server %s.", servername))
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
