local skynet = require "skynet"
local util = require "util"
local timer = require "timer"
local queue = require "skynet.queue"
local sharedata = require "sharedata"

local assert = assert
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local table = table
local math = math
local randomseed = math.randomseed
local random = math.random
local floor = math.floor

local guild_list = {}
local rank_list = {}
local role_list = {}
local apply = {}
local server_mgr
local error_code
local guildtechdata
local develop_skill
local stock_skill_id
local level_1_exp
local cs = queue()

local PAGE_GUILD = 10
local GUILD_EFFECT_DEVELOP = 1
local GUILD_EFFECT_STOCK = 6

local CMD = {}

local function add(info)
    local skill = info.skill
    if not skill then
        skill = {}
        info.skill = skill
    end
    for k, v in pairs(guildtechdata) do
        if not skill[k] then
            skill[k] = {
                id = k,
                exp = 0,
                level = 0,
                status = 0,
            }
        end
    end
    local ds = skill[develop_skill.id]
    if ds.level == 0 then
        ds.exp = level_1_exp[develop_skill.exp]
        ds.level = 1
    end
    if not info.count_limit then
        info.count_limit = ds.level * develop_skill.perlevel
    end
    local l = #rank_list
    if info.rank == 0 then
        info.rank = l + 1
    end
    local g = skynet.newservice("guild")
    skynet.call(g, "lua", "open", info, stock_skill_id, random(300))
    local si = {
        id = info.id,
        name = info.name,
        icon = info.icon,
        addr = g,
        rank = info.rank,
        active = info.active,
        count = info.count,
        count_limit = info.count_limit,
        apply_level = info.apply_level,
        apply_vip = info.apply_vip,
    }
    local key = util.gen_key(info.id%1000, info.name)
    guild_list[key] = si
    guild_list[info.id] = si
    rank_list[l+1] = si
    for k, v in pairs(info.member) do
        role_list[k] = si
    end
    for k, v in pairs(info.apply) do
        local p = apply[k]
        if not p then
            p = {}
            apply[k] = p
        end
        p[info.id] = g
    end
    return si
end

local function del(si, a)
    local key = util.gen_key(si.id%1000, si.name)
    guild_list[key] = nil
    guild_list[si.id] = nil
    assert(rank_list[si.rank].id==si.id, string.format("Mismatch guild %d rank %d.", si.id, si.rank))
    table.remove(rank_list, si.rank)
    for i = si.rank, #rank_list do
        local ni = rank_list[i]
        ni.rank = i
        skynet.send(ni.addr, "lua", "broadcast_update", "rank", i)
    end
    for k, v in ipairs(a) do
        local p = apply[v]
        p[si.id] = nil
    end
    pcall(skynet.call, si.addr, "lua", "exit")
end

local function save()
    for k, v in ipairs(rank_list) do
        skynet.call(v.addr, "lua", "save")
    end
end

local function del_apply(roleid)
    local p = apply[roleid]
    if p then
        for k, v in pairs(p) do
            skynet.call(v, "lua", "del_apply", roleid)
        end
        apply[roleid] = nil
    end
end

local function predict_2(l, r)
    return l.active > r.active
end
local function update_day(od, nd, owd, nwd)
    for k, v in ipairs(rank_list) do
        v.active = skynet.call(v.addr, "lua", "update_day")
    end
    table.sort(rank_list, predict_2)
    for k, v in ipairs(rank_list) do
        v.rank = k
        skynet.send(v.addr, "lua", "broadcast_update", "rank", k, true)
    end
end

-- TODO: update active, count_limit, apply_level, apply_vip
function CMD.update(guildid, key, value)
    local si = guild_list[guildid]
    if si then
        si[key] = value
    end
end

function CMD.found(roleid, server, name)
    if role_list[roleid] then
        return error_code.ALREADY_HAS_GUILD
    end
    local server_list = skynet.call(server_mgr, "lua", "get_all")
    for k, v in pairs(server_list) do
        local key = util.gen_key(k, name)
        if guild_list[key] then
            return error_code.GUILD_NAME_EXIST
        end
    end
    local si = add({
        id = skynet.call(server, "lua", "gen_guild"),
        name = name,
        icon = "",
        notice = "",
        exp = 0,
        level = 1,
        rank = 0,
        active = 0,
        apply_level = 0,
        apply_vip = 0,
        count = 0,
        log = {},
        member = {},
        apply = {},
        skill = {},
    })
    skynet.call(si.addr, "lua", "own", roleid)
    si.count = si.count + 1
    role_list[roleid] = si
    del_apply(roleid)
    return error_code.OK, si.addr, si.id
end

function CMD.accept(chief, roleid)
    local si = role_list[chief]
    if not si then
        return error_code.NOT_JOIN_GUILD
    end
    if role_list[roleid] then
        return error_code.TARGET_HAS_GUILD
    end
    if si.count >= si.count_limit then
        return error_code.GUILD_MEMBER_LIMIT
    end
    local r, update = skynet.call(si.addr, "lua", "accept", chief, roleid)
    if r ~= error_code.OK then
        return r
    end
    si.count = si.count + 1
    role_list[roleid] = si
    del_apply(roleid)
    return r, update
end

function CMD.accept_all(chief)
    local si = role_list[chief]
    if not si then
        return error_code.NOT_JOIN_GUILD
    end
    if si.count >= si.count_limit then
        return error_code.GUILD_MEMBER_LIMIT
    end
    local r, a, update = skynet.call(si.addr, "lua", "accept_all", chief)
    if r ~= error_code.OK then
        return r
    end
    si.count = si.count + #a
    for k, v in ipairs(a) do
        role_list[v] = si
        del_apply(v)
    end
    return r, update
end

function CMD.refuse(chief, roleid)
    local si = role_list[chief]
    if not si then
        return error_code.NOT_JOIN_GUILD
    end
    local r = skynet.call(si.addr, "lua", "refuse", chief, roleid)
    if r ~= error_code.OK then
        return r
    end
    local p = apply[roleid]
    if p then
        p[si.id] = nil
    end
    return r
end

function CMD.refuse_all(chief)
    local si = role_list[chief]
    if not si then
        return error_code.NOT_JOIN_GUILD
    end
    local r, a = skynet.call(si.addr, "lua", "refuse_all", chief)
    if r ~= error_code.OK then
        return r
    end
    for k, v in ipairs(a) do
        local p = apply[v]
        if p then
            p[si.id] = nil
        end
    end
    return r
end

function CMD.expel(chief, roleid)
    local si = role_list[chief]
    if not si then
        return error_code.NOT_JOIN_GUILD
    end
    local r, update = skynet.call(si.addr, "lua", "expel", chief, roleid)
    if r ~= error_code.OK then
        return r
    end
    role_list[roleid] = nil
    si.count = si.count - 1
    return r, update
end

function CMD.get(roleid)
    return role_list[roleid]
end

function CMD.simple_info(id)
    local si = guild_list[id]
    if si then
        return skynet.call(si.addr, "lua", "simple_info")
    end
end

function CMD.query(roleid, name)
    local r = {}
    local id = tonumber(name)
    if id then
        local si = guild_list[id]
        if si then
            r[#r+1] = skynet.call(si.addr, "lua", "rank_info", roleid)
        end
    end
    local server_list = skynet.call(server_mgr, "lua", "get_all")
    for k, v in pairs(server_list) do
        local key = util.gen_key(k, name)
        local si = guild_list[key]
        if si then
            r[#r+1] = skynet.call(si.addr, "lua", "rank_info", roleid)
        end
    end
    return r
end

function CMD.list(roleid, page)
    local b, e = (page-1)*PAGE_GUILD+1, page*PAGE_GUILD
    local l = #rank_list
    if e > l then
        e = l
    end
    local r = {}
    for i = b, e do
        r[#r+1] = skynet.call(rank_list[i].addr, "lua", "rank_info", roleid)
    end
    return r, (l+PAGE_GUILD-1)//PAGE_GUILD
end

function CMD.query_apply(roleid)
    local p = apply[roleid]
    if p then
        local r = {}
        for k, v in pairs(p) do
            r[#r+1] = skynet.call(v, "lua", "rank_info", roleid)
        end
        return r
    end
end

function CMD.apply(roleid, guildid, level, vip)
    if role_list[roleid] then
        return error_code.ALREADY_HAS_GUILD
    end
    if guildid then
        local si = guild_list[guildid]
        if not si then
            return error_code.GUILD_NOT_EXIST
        end
        if si.count >= si.count_limit then
            return error_code.GUILD_MEMBER_LIMIT
        end
        local p = apply[roleid]
        if p and p[guildid] then
            return error_code.ALREADY_APPLY_GUILD
        end
        if level >= si.apply_level and vip >= si.apply_vip then
            skynet.call(si.addr, "lua", "join", roleid)
            si.count = si.count + 1
            role_list[roleid] = si
            del_apply(roleid)
            return error_code.OK, si.addr, si.id
        else
            local info = skynet.call(si.addr, "lua", "apply", roleid)
            if not p then
                p = {}
                apply[roleid] = p
            end
            p[guildid] = si.addr
            return error_code.OK, info
        end
    else
        for k, v in ipairs(rank_list) do
            if level >= v.apply_level and vip >= v.apply_vip and v.count < v.count_limit then
                skynet.call(v.addr, "lua", "join", roleid)
                v.count = v.count + 1
                role_list[roleid] = v
                del_apply(roleid)
                return error_code.OK, v.addr, v.id
            end
        end
        return error_code.RANDOM_JOIN_GUILD_LIMIT
    end
end

function CMD.dismiss(roleid)
    local si = role_list[roleid]
    if not si then
        return error_code.NOT_JOIN_GUILD
    end
    local r, a = skynet.call(si.addr, "lua", "dismiss", roleid)
    if r ~= error_code.OK then
        return r
    end
    role_list[roleid] = nil
    si.count = si.count - 1
    del(si, a)
    return r
end

function CMD.quit(roleid)
    local si = role_list[roleid]
    if not si then
        return error_code.NOT_JOIN_GUILD
    end
    local r, update = skynet.call(si.addr, "lua", "quit", roleid)
    if r ~= error_code.OK then
        return r
    end
    role_list[roleid] = nil
    si.count = si.count - 1
    return r
end

function CMD.shutdown()
    save()
    timer.del_day_routine("guild_rank")
end

function CMD.day_routine(key, od, nd, owd, nwd)
    timer.call_day_routine(key, od, nd, owd, nwd)
end

local function predict_1(l, r)
    return l.rank < r.rank
end
skynet.start(function()
    randomseed(floor(skynet.time()))
    error_code = sharedata.query("error_code")
    guildtechdata = sharedata.query("guildtechdata")
    local guild_tech_effect = sharedata.query("guild_tech_effect")
    develop_skill = assert(guild_tech_effect[GUILD_EFFECT_DEVELOP], string.format("No guild skill effect %d.", GUILD_EFFECT_DEVELOP))
    local stock_skill = assert(guild_tech_effect[GUILD_EFFECT_STOCK], string.format("No guild skill effect %d.", GUILD_EFFECT_STOCK))
    stock_skill_id = stock_skill.id
    local expdata = sharedata.query("expdata")
    level_1_exp = expdata[1]
    server_mgr = skynet.queryservice("server_mgr")
    local master = skynet.queryservice("dbmaster")
    local guilddb = skynet.call(master, "lua", "get", "guilddb")
    local index = 0
    local list = {}
    repeat
        local res = skynet.call(guilddb, "lua", "scan", index)
        index = res[1]
        for k, v in ipairs(res[2]) do
            if not list[v] then
                -- NOTICE: v is string, not number
                add(skynet.unpack(skynet.call(guilddb, "lua", "get", v)))
                list[v] = true
            end
        end
    until index == "0"
    table.sort(rank_list, predict_1)
    -- NOTICE: repair rank
    for k, v in ipairs(rank_list) do
        if v.rank ~= k then
            skynet.call(v.addr, "lua", "update", "rank", k)
        end
    end
    timer.add_day_routine("guild_rank", update_day)

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            cs(f, ...)
        else
            skynet.retpack(cs(f, ...))
        end
	end)
end)
