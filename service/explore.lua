local skynet = require "skynet"

local assert = assert
local string = string

local data

local CMD = {}

function CMD.open(d)
    data = d
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
