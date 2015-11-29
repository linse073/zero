local skynet = require "skynet"

local assert = assert
local string = string

local role_list = {}

local CMD = {}

function CMD.enter(roleid, agent)
    assert(not role_list[roleid], string.format("Role already enter %d.", roleid))
    role_list[roleid] = agent
end

function CMD.logout(roleid)
    role_list[roleid] = nil
end

function CMD.get(roleid)
    return assert(role_list[roleid], string.format("No role %d.", roleid))
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
