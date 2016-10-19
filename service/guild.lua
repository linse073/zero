local skynet = require "skynet"
local timer = require "timer"
local sharedata = require "sharedata"
local util = require "util"
local func = require "func"
local queue = require "skynet.queue"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local string = string
local floor = math.floor

local error_code
local data
local guilddb
local role_mgr
local offline_mgr
local cs = queue()

local guild_title
local expel_content

local GUILD_POS_MEMBER = 0
local GUILD_POS_A_CHIEF = 1
local GUILD_POS_CHIEF = 2
local MAIL_TYPE_GUILD = 8

local CMD = {}

local function save()
    local pm = {}
    for k, v in pairs(data.member) do
        local ri, online = skynet.call(role_mgr, "lua", "get_rank_info", v.id)
        local nm = {}
        if v.level ~= ri.level then
            v.level = ri.level
            nm.level = ri.level
        end
        if v.fight_point ~= ri.fight_point then
            v.fight_point = ri.fight_point
            nm.fight_point = ri.fight_point
        end
        if v.online ~= online then
            v.online = online
            nm.online = online
        end
        if not util.empty(nm) then
            nm.id = v.id
            pm[#pm+1] = nm
        end
    end
    if #pm > 0 then
        local update = {member=pm}
        CMD.broadcast("update_user", {update={guild=update}})
    end
    for k, v in pairs(data.apply) do
        local ri, online = skynet.call(role_mgr, "lua", "get_rank_info", v.id)
        if v.level ~= ri.level then
            v.level = ri.level
        end
        if v.fight_point ~= ri.fight_point then
            v.fight_point = ri.fight_point
        end
        if v.online ~= online then
            v.online = online
        end
    end
    skynet.call(guilddb, "lua", "save", skynet.packstring(data))
end

local function delay_save()
    timer.del_once_routine("delay_save")
    timer.add_routine("save_guild", save, 300)
end

local function add(roleid, pos)
    assert(not data.member[roleid], string.format("Already member %d.", roleid))
    local info, online = skynet.call(role_mgr, "lua", "get_rank_info", roleid)
    local m = {
        id = info.id,
        name = info.name,
        prof = info.prof,
        level = info.level,
        fight_point = info.fight_point,
        pos = pos or GUILD_POS_MEMBER,
        contribute = info.contribute,
        last_login_time = info.last_login_time or 0,
        online = online,
    }
    data.member[roleid] = m
    data.count = data.count + 1
    return m
end

function CMD.open(info, delay)
    data = info

    guild_title = func.get_string(198100001)
    expel_content = func.get_string(198100002)
    error_code = sharedata.query("error_code")
    local master = skynet.queryservice("dbmaster")
    guilddb = skynet.call(master, "lua", "get", "guilddb")
    role_mgr = skynet.queryservice("role_mgr")
    offline_mgr = skynet.queryservice("offline_mgr")
    time.add_once_routine("delay_save", delay_save, delay)
end

function CMD.join(roleid, pos)
    local m = add(roleid, pos)
    local update = {member={m}}
    CMD.broadcast("update_user", {update={guild=update}}, roleid)
end

function CMD.accept(chief, roleid)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= GUILD_POS_CHIEF or m.pos ~= GUILD_POS_A_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    if not data.apply[roleid] then
        return error_code.TARGET_NOT_APPLY_GUILD
    end
    CMD.join(roleid)
    local agent = skynet.call(role_mgr, "lua", "get", roleid)
    if agent then
        skynet.call(agent, "lua", "action", "guild", "join", skynet.self())
    end
    return error_code.OK
end

function CMD.accept_all(chief)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= GUILD_POS_CHIEF or m.pos ~= GUILD_POS_A_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    -- TODO: if data.apply is empty?
    local range = {}
    for k, v in pairs(data.member) do
        range[#range+1] = v.id
    end
    local u = {}
    local a = {}
    for k, v in pairs(data.apply) do
        u[#u+1] = add(v.id)
        a[#a+1] = v.id
    end
    local update = {member=u}
    skynet.call(role_mgr, "lua", "broadcast_range", "update_user", {update={guild=update}}, range)
    for k, v in ipairs(a) do
        local agent = skynet.call(role_mgr, "lua", "get", v)
        if agent then
            skynet.call(agent, "lua", "action", "guild", "join", skynet.self())
        end
    end
    return error_code.OK, a
end

function CMD.refuse(chief, roleid)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= GUILD_POS_CHIEF or m.pos ~= GUILD_POS_A_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    if not data.apply[roleid] then
        return error_code.TARGET_NOT_APPLY_GUILD
    end
    data.apply[roleid] = nil
    return error_code.OK, data.id
end

function CMD.refuse_all(chief)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= GUILD_POS_CHIEF or m.pos ~= GUILD_POS_A_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    local a = {}
    for k, v in pairs(data.apply) do
        a[#a+1] = v.id
    end
    data.apply = {}
    return error_code.OK, data.id, a
end

function CMD.expel(chief, roleid)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= GUILD_POS_CHIEF or m.pos ~= GUILD_POS_A_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    local rm = data.member[roleid]
    if not rm then
        return error_code.TARGET_NOT_GUILD_MEMBER
    end
    if rm.pos == GUILD_POS_A_CHIEF and m.pos ~= GUILD_POS_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    data.member[roleid] = nil
    data.count = data.count - 1
    local update = {member={{id=roleid, del=true}}}
    CMD.broadcast("update_user", {update={guild=update}})
    local mail = {
        type = MAIL_TYPE_GUILD,
        time = floor(skynet.time()),
        title = guild_title,
        content = string.format(expel_content, m.name),
        del = true,
    }
    skynet.call(offline_mgr, "lua", "add", "mail", roleid, mail)
    return error_code.OK
end

function CMD.login(roleid, now)
    local m = data.member[roleid]
    if m then
        m.last_login_time = now
        m.online = true
        local update = {member={{last_login_time=now, online=true}}}
        CMD.broadcast("update_user", {update={guild=update}}, roleid)
        return CMD.pack_info()
    end
end

function CMD.update(key, value)
    data[key] = value
end

function CMD.get(key)
    return data[key]
end

function CMD.broadcast_update(key, value)
    data[key] = value
    local update = {}
    update[key] = value
    CMD.broadcast("update_user", {update={guild={info=update}}})
end

function CMD.rank_info(roleid)
    return {
        id = data.id,
        name = data.name,
        icon = data.icon,
        notice = data.notice,
        level = data.level,
        rank = data.rank,
        count = data.count,
        apply = data.apply[roleid] ~= nil,
    }
end

function CMD.apply(roleid)
    assert(not data.apply[roleid], string.format("Role %d already apply guild %d.", roleid, data.id))
    local info = skynet.call(role_mgr, "lua", "get_rank_info", roleid)
    local a = {
        id = info.id,
        name = info.name,
        prof = info.prof,
        level = info.level,
        fight_point = info.fight_point,
        time = floor(skynet.time()),
    }
    data.apply[roleid] = a
end

-- TODO: add guild log
function CMD.pack_info()
    local info = {
        id = data.id,
        name = data.name,
        icont = data.icon,
        notice = data.notice,
        exp = data.exp,
        level = data.level,
        rank = data.rank,
        active = data.active,
        apply_level = data.apply_level,
        apply_vip = data.apply_vip,
    }
    local m = {}
    for k, v in pairs(data.member) do
        m[#m+1] = v
    end
    return {info=info, log=data.log, member=m}
end

function CMD.broadcast(msg, info, exclude)
    local range = {}
    for k, v in pairs(data.member) do
        if v.id ~= exclude then
            range[#range+1] = v.id
        end
    end
    if #range > 0 then
        skynet.call(role_mgr, "lua", "broadcast_range", msg, info, range)
    end
end

function CMD.del_apply(roleid)
    data.apply[roleid] = nil
end

function CMD.dismiss(roleid)
    local m = data.member[roleid]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= GUILD_POS_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    if data.count > 1 then
        return error_code.GUILD_DISMISS_LIMIT
    end
    data.member[roleid] = nil
    data.count = data.count - 1
    return error_code.OK, data
end

function CMD.shutdown()
    skynet.call(guilddb, "lua", "save", skynet.packstring(data))
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
            cs(f, ...)
        else
            skynet.retpack(cs(f, ...))
        end
	end)
end)
