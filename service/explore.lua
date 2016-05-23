local skynet = require "skynet"
local timer = require "timer"

local assert = assert
local string = string

local data

local CMD = {}

local function update()
    local now = skynet.time()
end

function CMD.open(d)
    data = d
    timer.add_second_routine("update_explore", update)
end

function CMD.explore(roleid)
end

function CMD.quit(roleid)
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
