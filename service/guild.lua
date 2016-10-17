local skynet = require "skynet"
local timer = require "timer"

local assert = assert

local info
local guilddb

local CMD = {}

local function save()
    skynet.call(guilddb, "lua", "save", skynet.packstring(info))
end

local function delay_save()
    timer.del_once_routine("delay_save")
    timer.add_routine("save_guild", save, 300)
end

function CMD.open(i, delay)
    info = i

    local master = skynet.queryservice("dbmaster")
    guilddb = skynet.call(master, "lua", "get", "guilddb")
    time.add_once_routine("delay_save", delay_save, delay)
end

function CMD.active()
    return info.active
end

function CMD.update_rank(rank)
    info.rank = rank
    -- TODO: broadcast
end

function CMD.base_info(roleid)
end

function CMD.info()
    return info
end

function CMD.broadcast()
end

function CMD.del_proposer(roleid)
    info.proposer[roleid] = nil
end

function CMD.shutdown()
    save()
    timer.del_routine("save_guild")
end

function CMD.once_routine(key)
    timer.call_once_routine(key)
end

function CMD.routine(key)
    timer.call_routine(key)
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
