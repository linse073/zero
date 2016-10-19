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
local server_list
local error_code
local cs = queue()

local PAGE_GUILD = 10
local GUILD_POS_CHIEF = 2

local CMD = {}

local function add(info)
    local g = skynet.newservice("guild")
    skynet.call(g, "lua", "open", info, random(300))
    local key = util.gen_key(info.id%1000, info.name)
    guild_list[key] = g
    guild_list[info.id] = g
    local l = #rank_list
    if info.rank == 0 then
        info.rank = l + 1
    end
    rank_list[l+1] = {
        addr = g,
        rank = info.rank,
        active = info.active,
    }
    for k, v in pairs(info.member) do
        role_list[v.id] = g
    end
    for k, v in pairs(info.apply) do
        local p = apply[v.id]
        if not p then
            p = {}
            apply[v.id] = p
        end
        p[info.id] = g
    end
    return g
end

local function del(g, info)
    assert(util.empty(info.member) and info.count==0, string.format("Not empty guild %d.", info.id))
    local key = util.gen_key(info.id%1000, info.name)
    assert(guild_list[key]==g, string.format("Mismatch guild key %s.", key))
    guild_list[key] = nil
    guild_list[info.id] = nil
    assert(rank_list[info.rank].addr==g, string.format("Mismatch guild rank %d.", info.rank))
    table.remove(rank_list, info.rank)
    for i = info.rank, #rank_list do
        local ni = rank_list[i]
        ni.rank = i
        skynet.send(ni.addr, "lua", "broadcast_update", "rank", i)
    end
    for k, v in pairs(info.apply) do
        local p = apply[v.id]
        p[info.id] = nil
    end
end

local function save()
    for k, v in pairs(guild_list) do
        skynet.call(v, "lua", "save")
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
        v.active = skynet.call(v.addr, "lua", "get", "active")
    end
    table.sort(rank_list, predict_2)
    for k, v in ipairs(rank_list) do
        v.rank = k
        skynet.send(v.addr, "lua", "broadcast_update", "rank", k)
    end
end

function CMD.found(roleid, server, name)
    if role_list[roleid] then
        return error_code.ALREADY_HAS_GUILD
    end
    for k, v in pairs(server_list) do
        if guild_list[util.gen_key(k, name)] then
            return error_code.GUILD_NAME_EXIST
        end
    end
    local g = add({
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
    })
    skynet.call(g, "lua", "join", roleid, GUILD_POS_CHIEF)
    role_list[roleid] = g
    del_apply(roleid)
    return error_code.OK, g
end

function CMD.accept(chief, roleid)
    local g = role_list[chief]
    if not g then
        return error_code.NOT_JOIN_GUILD
    end
    if role_list[roleid] then
        return error_code.TARGET_HAS_GUILD
    end
    local r = skynet.call(g, "lua", "accept", chief, roleid)
    if r ~= error_code.OK then
        return r
    end
    role_list[roleid] = g
    del_apply(roleid)
    return error_code.OK
end

function CMD.accept_all(chief)
    local g = role_list[chief]
    if not g then
        return error_code.NOT_JOIN_GUILD
    end
    local r, a = skynet.call(g, "lua", "accept_all", chief)
    if r ~= error_code.OK then
        return r
    end
    for k, v in ipairs(a) do
        role_list[v] = g
        del_apply(v)
    end
    return error_code.OK
end

function CMD.refuse(chief, roleid)
    local g = role_list[chief]
    if not g then
        return error_code.NOT_JOIN_GUILD
    end
    local r, id = skynet.call(g, "lua", "refuse", chief, roleid)
    if r ~= error_code.OK then
        return r
    end
    local p = apply[roleid]
    if p then
        p[id] = nil
    end
    return error_code.OK
end

function CMD.refuse_all(chief)
    local g = role_list[chief]
    if not g then
        return error_code.NOT_JOIN_GUILD
    end
    local r, id, a = skynet.call(g, "lua", "refuse_all", chief)
    if r ~= error_code.OK then
        return r
    end
    for k, v in ipairs(a) do
        local p = apply[v]
        if p then
            p[id] = nil
        end
    end
    return error_code.OK
end

function CMD.expel(chief, roleid)
    local g = role_list[chief]
    if not g then
        return error_code.NOT_JOIN_GUILD
    end
    local r = skynet.call(g, "lua", "expel", chief, roleid)
    if r ~= error_code.OK then
        return r
    end
    role_list[roleid] = nil
    return error_code.OK
end

function CMD.get(roleid)
    return role_list[roleid]
end

function CMD.query(roleid, name)
    local r = {}
    local id = tonumber(name)
    if id then
        local g = guild_list[id]
        if g then
            r[#r+1] = skynet.call(g, "lua", "rank_info", roleid)
        end
    end
    for k, v in pairs(server_list) do
        local g = guild_list[util.gen_key(k, name)]
        if g then
            r[#r+1] = skynet.call(g, "lua", "rank_info", roleid)
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
    local g = {}
    for i = b, e do
        g[#g+1] = skynet.call(rank_list[i].addr, "lua", "rank_info", roleid)
    end
    return r, l
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

function CMD.apply(roleid, guildid)
    if role_list[roleid] then
        return error_code.ALREADY_HAS_GUILD
    end
    local g = guild_list[guildid]
    if not g then
        return error_code.GUILD_NOT_EXIST
    end
    local p = apply[roleid]
    if p and p[guildid] then
        return error_code.ALREADY_APPLY_GUILD
    end
    skynet.call(g, "lua", "apply", roleid)
    if not p then
        p = {}
        apply[roleid] = p
    end
    p[guildid] = g
    return error_code.OK
end

function CMD.dismiss(roleid)
    local g = role_list[chief]
    if not g then
        return error_code.NOT_JOIN_GUILD
    end
    local r, info = skynet.call(g, "lua", "dismiss", roleid)
    if r ~= error_code.OK then
        return r
    end
    role_list[roleid] = nil
    del(g, info)
    return error_code.OK
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
    local server_mgr = skynet.queryservice("server_mgr")
    server_list = skynet.call(server_mgr, "lua", "get_all")
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
