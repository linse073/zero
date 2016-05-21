local skynet = require "skynet"

local assert = assert
local string = string

local data

local CMD = {}

function CMD.open(d)
    data = d
end

function CMD.explore(roleid)
end

function CMD.exit(roleid)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            f(...)
        else
            skynet.retpack(f(...))
        end
	end)
end)
