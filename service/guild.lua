local skynet = require "skynet"
local timer = require "timer"
local sharedata = require "sharedata"

local assert = assert
local string = string

local error_code
local info
local guilddb
local role_mgr

local GUILD_POS_MEMBER = 0
local GUILD_POS_A_CHIEF = 1
local GUILD_POS_CHIEF = 2

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
    assert(not info.member[roleid], string.format("Already member %d.", roleid))
    local info, online = skynet.call(role_mgr, "lua", "get_rank_info", roleid)
    info.member[roleid] = {
        id = info.id,
        name = info.name,
        prof = info.prof,
        level = info.level,
        fight_point = info.fight_point,
        pos = pos or GUILD_POS_MEMBER,
        contribute = 0,
        last_login_time = info.last_login_time or 0,
        online = online,
    }
    info.count = info.count + 1
end

function CMD.del(roleid)
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
    if m.pos ~= GUILD_POS_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    if info.count > 1 then
        return error_code.GUILD_DISMISS_LIMIT
    end
    info.member[roleid] = nil
    info.count = info.count - 1
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
