local skynet = require "skynet"
local timer = require "timer"
local sharedata = require "sharedata"

local assert = assert

local error_code
local info
local guilddb
local role_mgr

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

    error_code = sharedata.query("error_code")
    local master = skynet.queryservice("dbmaster")
    guilddb = skynet.call(master, "lua", "get", "guilddb")
    role_mgr = skynet.queryservice("role_mgr")
    time.add_once_routine("delay_save", delay_save, delay)
end

function CMD.active()
    return info.active
end

function CMD.join(roleid, pos)
end

function CMD.update_rank(rank)
    info.rank = rank
    -- TODO: broadcast
end

function CMD.rank_info(roleid)
end

function CMD.apply(roleid)
end

function CMD.pack_info()
end

function CMD.broadcast()
end

function CMD.del_apply(roleid)
    info.apply[roleid] = nil
end

function CMD.dismiss(roleid)
    local m = info.member[roleid]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
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
