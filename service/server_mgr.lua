local skynet = require "skynet"

local assert = assert
local string = string

local server_list = {}
local gate

local CMD = {}

function CMD.register(serverid, address)
    assert(not server_list[serverid], string.format("Already register server %d.", serverid))
    server_list[serverid] = address
end

function CMD.register_gate(address)
    assert(not gate, "Already register gate.")
    gate = address
end

function CMD.shutdown()
    for k, v in pairs(server_list) do
        skynet.call(v, "lua", "shutdown")
    end
    skynet.call(gate, "lua", "shutdown")
end

function CMD.get(serverid)
    return assert(server_list[serverid], string.format("No server %d.", serverid))
end

function CMD.get_all()
    return server_list
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
