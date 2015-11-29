local skynet = require "skynet"

local assert = assert
local string = string

local slave_list = {}

local CMD = {}

function CMD.register(server, name, address)
    local l = slave_list[server]
    if not l then
        l = {}
        slave_list[server] = l
    end
    assert(not l[name], string.format("Already register database slave %s %s.", server, name))
    l[name] = address
end

function CMD.get(server, name)
    local address
    local l = slave_list[server]
    if l then
        address = l[name]
    end
    if not address then
        local g = slave_list["global"]
        if g then
            address = g[name]
        end
    end
    assert(address, string.format("No database slave %s %s.", server, name))
    return address
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
