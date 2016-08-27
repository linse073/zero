local skynet = require "skynet"

local assert = assert

local slave_list = {}

local CMD = {}

function CMD.get(slave)
    return slave_list[slave]
end

skynet.start(function()
    local r = {
        "slave_level",
        "slave_fight",
        "slave_arena",
        "slave_explore",
        "slave_stage",
    }
    for k, v in ipairs(r) do
        local slave = skynet.newservice("rank_slave", v)
        slave_list[k] = slave
    end

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            f(...)
        else
            skynet.retpack(f(...))
        end
	end)
end)
