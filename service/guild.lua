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
local table = table
local math = math
local randomseed = math.randomseed
local random = math.random

local guildtechdata
local expdata
local error_code
local data
local skill
local guilddb
local role_mgr
local offline_mgr
local cs = queue()
local a_chief = 0
local stock_skill_id

local guild_title
local expel_content

local POS_MEMBER = 0
local POS_A_CHIEF = 1
local POS_CHIEF = 2

local MAIL_TYPE_GUILD = 8

local LOG_ADD_MEMBER = 1
local LOG_PROMOTE = 2
local LOG_SKILL = 3
local LOG_CONTRIBUTE = 4

local RAND_FACTOR = 10000
local GUILD_EFFECT_DEVELOP = 1

local CMD = {}

local function save()
    local pm = {}
    for k, v in pairs(data.member) do
        local ri, online = skynet.call(role_mgr, "lua", "get_rank_info", k)
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
            nm.id = k
            pm[#pm+1] = nm
        end
    end
    if #pm > 0 then
        local update = {member=pm}
        CMD.broadcast("update_user", {update={guild=update}})
    end
    for k, v in pairs(data.apply) do
        local ri = skynet.call(role_mgr, "lua", "get_rank_info", k)
        if v.level ~= ri.level then
            v.level = ri.level
        end
        if v.fight_point ~= ri.fight_point then
            v.fight_point = ri.fight_point
        end
    end
    skynet.call(guilddb, "lua", "set", data.id, skynet.packstring(data))
end

local function delay_save()
    timer.del_once_routine("delay_save")
    timer.add_routine("save_guild", save, 300)
end

local function add_log(log)
    local l = data.log
    local len = #l + 1
    l[len] = log
    if len >= 100 then
        table.remove(l, 1)
    end
    return log
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
        pos = pos or POS_MEMBER,
        contribute = 0,
        explore = 0,
        active = 0,
        last_login_time = info.last_login_time or 0,
        online = online,
    }
    data.member[roleid] = m
    data.count = data.count + 1
    local l = add_log({
        type = LOG_ADD_MEMBER,
        id = roleid,
        name = info.name,
        time = floor(skynet.time()),
    })
    return m, l
end

function CMD.open(info, sid, delay)
    randomseed(floor(skynet.time()))
    guild_title = func.get_string(198100001)
    expel_content = func.get_string(198100002)
    guildtechdata = sharedata.query("guildtechdata")
    expdata = sharedata.query("expdata")
    error_code = sharedata.query("error_code")
    data = info
    stock_skill_id = sid
    skill = {}
    for k, v in pairs(info.skill) do
        skill[k] = {
            v,
            assert(guildtechdata[k], string.format("No guild tech data %d.", k)),
        }
    end
    for k, v in pairs(data.member) do
        if v.pos == POS_A_CHIEF then
            a_chief = a_chief + 1
        end
    end

    local master = skynet.queryservice("dbmaster")
    guilddb = skynet.call(master, "lua", "get", "guilddb")
    role_mgr = skynet.queryservice("role_mgr")
    offline_mgr = skynet.queryservice("offline_mgr")
    timer.add_once_routine("delay_save", delay_save, delay)
end

function CMD.own(roleid)
    add(roleid, POS_CHIEF)
end

function CMD.join(roleid)
    local m, l = add(roleid)
    local update = {member={m}, log={l}}
    CMD.broadcast("update_user", {update={guild=update}}, roleid)
end

function CMD.accept(chief, roleid)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= POS_CHIEF and m.pos ~= POS_A_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    if not data.apply[roleid] then
        return error_code.TARGET_NOT_APPLY_GUILD
    end
    if data.count >= data.count_limit then
        return error_code.GUILD_MEMBER_LIMIT
    end
    local range = {}
    for k, v in pairs(data.member) do
        if chief ~= k then
            range[#range+1] = k
        end
    end
    local m, l = add(roleid)
    local update = {member={m}, log={l}}
    if #range > 0 then
        skynet.call(role_mgr, "lua", "broadcast_range", "update_user", {update={guild=update}}, range)
    end
    local agent = skynet.call(role_mgr, "lua", "get", roleid)
    if agent then
        skynet.send(agent, "lua", "action", "guild", {skynet.self(), data.id})
    end
    return error_code.OK, update
end

local function predict(l, r)
    return l.time < r.time
end
function CMD.accept_all(chief)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= POS_CHIEF and m.pos ~= POS_A_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    if data.count >= data.count_limit then
        return error_code.GUILD_MEMBER_LIMIT
    end
    local a = {}
    local update
    if not util.empty(data.apply) then
        local range = {}
        for k, v in pairs(data.member) do
            if k ~= chief then
                range[#range+1] = k
            end
        end
        local ta = {}
        for k, v in pairs(data.apply) do
            ta[#ta+1] = v
        end
        table.sort(ta, predict)
        local len = #ta
        local d = data.count_limit - data.count
        if len > d then
            len = d
        end
        local u = {}
        local l = {}
        for i = 1, len do
            local v = ta[i]
            u[#u+1], l[#l+1] = add(v.id)
            a[#a+1] = v.id
        end
        update = {member=u, log=l}
        if #range > 0 then
            skynet.call(role_mgr, "lua", "broadcast_range", "update_user", {update={guild=update}}, range)
        end
        local ji = {skynet.self(), data.id}
        for k, v in ipairs(a) do
            local agent = skynet.call(role_mgr, "lua", "get", v)
            if agent then
                skynet.send(agent, "lua", "action", "guild", ji)
            end
        end
    end
    return error_code.OK, a, update
end

function CMD.refuse(chief, roleid)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= POS_CHIEF and m.pos ~= POS_A_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    if not data.apply[roleid] then
        return error_code.TARGET_NOT_APPLY_GUILD
    end
    data.apply[roleid] = nil
    return error_code.OK
end

function CMD.refuse_all(chief)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= POS_CHIEF and m.pos ~= POS_A_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    local a = {}
    for k, v in pairs(data.apply) do
        a[#a+1] = k
    end
    data.apply = {}
    return error_code.OK, a
end

function CMD.expel(chief, roleid)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= POS_CHIEF and m.pos ~= POS_A_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    local rm = data.member[roleid]
    if not rm then
        return error_code.TARGET_NOT_GUILD_MEMBER
    end
    if rm.pos == POS_A_CHIEF and m.pos ~= POS_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    data.member[roleid] = nil
    data.count = data.count - 1
    local update = {member={{id=roleid, del=true}}}
    CMD.broadcast("update_user", {update={guild=update}}, chief)
    local mail = {
        type = MAIL_TYPE_GUILD,
        time = floor(skynet.time()),
        title = guild_title,
        content = string.format(expel_content, m.name),
    }
    skynet.call(offline_mgr, "lua", "add", "mail", roleid, mail)
    local agent = skynet.call(role_mgr, "lua", "get", roleid)
    if agent then
        skynet.send(agent, "lua", "action", "guild")
    end
    return error_code.OK, update
end

function CMD.login(roleid, now)
    local m = data.member[roleid]
    if m then
        m.last_login_time = now
        m.online = true
        local update = {member={{id=roleid, last_login_time=now, online=true}}}
        CMD.broadcast("update_user", {update={guild=update}}, roleid)
        return CMD.pack_info()
    end
end

function CMD.update_day()
    for k, v in pairs(data.member) do
        v.active = floor(v.active * 0.9)
    end
    data.active = floor(data.active * 0.9)
    return data.active
end

function CMD.update(key, value)
    data[key] = value
end

function CMD.get(key)
    return data[key]
end

function CMD.broadcast_update(key, value, decay_active)
    data[key] = value
    local update = {}
    update[key] = value
    CMD.broadcast("update_user", {update={guild={info=update}}, decay_active=decay_active})
end

function CMD.config(chief, key, value)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= POS_CHIEF and m.pos ~= POS_A_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    data[key] = value
    local update = {}
    update[key] = value
    CMD.broadcast("update_user", {update={guild={info=update}}}, chief)
    return error_code.OK, update
end

function CMD.promote(chief, roleid)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= POS_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    if a_chief >= 2 then
        return error_code.PROMOTE_COUNT_LIMIT
    end
    local rm = data.member[roleid]
    if not rm then
        return error_code.TARGET_NOT_GUILD_MEMBER
    end
    if rm.pos ~= POS_MEMBER then
        return error_code.TARGET_PROMOTE_LIMIT
    end
    rm.pos = POS_A_CHIEF
    a_chief = a_chief + 1
    local l = add_log({
        type = LOG_PROMOTE,
        id = roleid,
        name = rm.name,
        time = floor(skynet.time()),
    })
    local update = {member={{id=roleid, pos=rm.pos}}, log={l}}
    CMD.broadcast("update_user", {update={guild=update}}, chief)
    return error_code.OK, update
end

function CMD.demote(chief, roleid)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= POS_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    local rm = data.member[roleid]
    if not rm then
        return error_code.TARGET_NOT_GUILD_MEMBER
    end
    if rm.pos ~= POS_A_CHIEF then
        return error_code.TARGET_DEMOTE_LIMIT
    end
    if rm.pos == POS_A_CHIEF then
        a_chief = a_chief - 1
    end
    rm.pos = POS_MEMBER
    local update = {member={{id=roleid, pos=rm.pos}}}
    CMD.broadcast("update_user", {update={guild=update}}, chief)
    return error_code.OK, update
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

function CMD.simple_info()
    return {
        id = data.id,
        name = data.name,
        icon = data.icon,
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
    return CMD.rank_info(roleid)
end

-- TODO: add guild log
function CMD.pack_info()
    local info = {
        id = data.id,
        name = data.name,
        icon = data.icon,
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
    local s = {}
    for k, v in pairs(data.skill) do
        s[#s+1] = v
    end
    return {info=info, log=data.log, member=m, skill=s}
end

function CMD.broadcast(msg, info, exclude)
    local range = {}
    for k, v in pairs(data.member) do
        if k ~= exclude then
            range[#range+1] = k
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
    if m.pos ~= POS_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    if data.count > 1 then
        return error_code.GUILD_DISMISS_LIMIT
    end
    data.member[roleid] = nil
    data.count = data.count - 1
    local a = {}
    for k, v in pairs(data.apply) do
        a[#a+1] = k
    end
    return error_code.OK, a
end

function CMD.demise(chief, roleid)
    local m = data.member[chief]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= POS_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    local rm = data.member[roleid]
    if not rm then
        return error_code.TARGET_NOT_GUILD_MEMBER
    end
    m.pos = POS_MEMBER
    if rm.pos == POS_A_CHIEF then
        a_chief = a_chief - 1
    end
    rm.pos = POS_CHIEF
    local l = add_log({
        type = LOG_PROMOTE,
        id = roleid,
        name = rm.name,
        time = floor(skynet.time()),
    })
    local update = {member={{id=roleid, pos=rm.pos}, {id=chief, pos=m.pos}}, log={l}}
    CMD.broadcast("update_user", {update={guild=update}}, chief)
    return error_code.OK, update
end

function CMD.quit(roleid)
    local m = data.member[roleid]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos == POS_CHIEF then
        return error_code.GUILD_CHIEF_QUIT_LIMIT
    end
    if m.pos == POS_A_CHIEF then
        a_chief = a_chief - 1
    end
    data.member[roleid] = nil
    data.count = data.count - 1
    local update = {member={{id=roleid, del=true}}}
    CMD.broadcast("update_user", {update={guild=update}})
    return error_code.OK
end

function CMD.get_apply(roleid)
    local m = data.member[roleid]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    if m.pos ~= POS_CHIEF and m.pos ~= POS_A_CHIEF then
        return error_code.NO_GUILD_PERMIT
    end
    local a = {}
    for k, v in pairs(data.apply) do
        a[#a+1] = v
    end
    return error_code.OK, a
end

function CMD.explore(roleid, num)
    local m = data.member[roleid]
    if m then
        m.explore = m.explore + num
        local update = {member={{id=roleid, explore=m.explore}}}
        CMD.broadcast("update_user", {update={guild=update}}, roleid)
        return update
    end
end

function CMD.upgrade_skill(roleid, use, rmb, id)
    local m = data.member[roleid]
    if not m then
        return error_code.NOT_GUILD_MEMBER
    end
    local s = skill[id]
    if not s then
        return error_code.ERROR_GUILD_SKILL
    end
    local sv = s[1]
    local sd = s[2]
    if sv.level >= sd.uplimit then
        return error_code.GUILD_SKILL_UPLIMIT
    end
    if sd.preTech > 0 then
        local ps = skill[sd.preTech]
        if not ps then
            return error_code.GUILD_PRESKILL_LIMIT
        end
        if ps[1].level < ps[2].uplimit then
            return error_code.GUILD_PRESKILL_LIMIT
        end
    end
    local mu = {id=roleid}
    local mul = 1
    local ur
    if use and sv.status > 0 then
        ur = 100 * sv.status
        if rmb < ur then
            return error_code.ROLE_RMB_LIMIT
        end
        mul = 10 * sv.status
        sv.status = 0
    else
        if m.explore < 100 then
            return error_code.GUILD_EXPLORE_LIMIT
        end
        m.explore = m.explore - 100
        mu.explore = m.explore
    end
    local addexp = 10 * mul
    m.contribute = m.contribute + addexp
    mu.contribute = m.contribute
    m.active = m.active + mul
    mu.active = m.active
    data.active = data.active + mul
    sv.exp = sv.exp + addexp
    local ol = sv.level
    local nl = ol + 1
    local e = assert(expdata[nl], string.format("No exp data %d.", nl))[sd.exp]
    while e > 0 do
        if sv.exp < e then
            break
        end
        sv.level = nl
        nl = nl + 1
        e = assert(expdata[nl], string.format("No exp data %d.", nl))[sd.exp]
    end
    if mul == 1 and sv.status == 0 then
        local r = random(RAND_FACTOR)
        if r <= 500 then
            sv.status = 2
        elseif r <= 1500 then
            sv.status = 1
        end
    end
    local update = {
        info = {active=data.active},
        member = {mu},
        skill = {sv},
    }
    CMD.broadcast("update_user", {update={guild=update}}, roleid)
    local cl
    if sd.effectType == GUILD_EFFECT_DEVELOP and ol ~= sv.level then
        data.count_limit = sv.level * sd.perlevel
        cl = data.count_limit
    end
    return error_code.OK, update, addexp, ur, cl
end

function CMD.stock_count()
    local s = skill[stock_skill_id]
    return 1 + s[1].level * s[2].perlevel
end

function CMD.shutdown()
    timer.del_once_routine("delay_save")
    timer.del_routine("save_guild")
    skynet.call(guilddb, "lua", "set", data.id, skynet.packstring(data))
end

function CMD.exit()
    timer.del_once_routine("delay_save")
    timer.del_routine("save_guild")
    skynet.call(guilddb, "lua", "del", data.id)
    assert(data.count==0, string.format("Guild %d has member %d.", data.id, data.count))
    skynet.exit()
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
