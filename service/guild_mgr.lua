local skynet = require "skynet"
local util = require "util"
local timer = require "timer"

local assert = assert
local pairs = pairs
local ipairs = ipairs
local table = table

local guild_list = {}
local rank_list = {}
local role_list = {}
local proposer = {}

local CMD = {}

local function add(info)
    local g = skynet.newservice("guild")
    skynet.call(g, "lua", "open", info)
    local serverid = info.id % 1000
    guild_list[util.gen_key(serverid, info.name)] = g
    guild_list[info.id] = g
    rank_list[#rank_list+1] = {
        addr = g,
        rank = info.rank,
        active = info.active,
    }
    for k, v in pairs(info.member) do
        role_list[v.id] = g
    end
    for k, v in pairs(info.proposer) do
        local p = proposer[v.id]
        if p then
            p[#p+1] = g
        else
            proposer[v.id] = {g}
        end
    end
end

local function predict_2(l, r)
    return l.active > r.active
end
local function update_day(od, nd, owd, nwd)
    for k, v in ipairs(rank_list) do
        v.active = skynet.call(v.addr, "lua", "active")
    end
    table.sort(rank_list, predict_2)
    for k, v in ipairs(rank_list) do
        v.rank = k
        skynet.call(v.addr, "lua", "update_rank", k)
    end
end

function CMD.create(serverid, name)
end

function CMD.get(roleid)
    return role_list[roleid]
end

function CMD.query(name)
end

function CMD.list(page)
end

function CMD.query_proposer(roleid)
end

function CMD.shutdown()
    timer.del_day_routine("guild_rank")
end

function CMD.day_routine(key, od, nd, owd, nwd)
    timer.call_day_routine(key, od, nd, owd, nwd)
end

local function predict_1(l, r)
    return l.rank < r.rank
end
skynet.start(function()
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
                local info = skynet.unpack(skynet.call(guilddb, "lua", "get", v))
                add(info)
                list[v] = true
            end
        end
    until index == "0"
    table.sort(rank_list, predict_1)
    timer.add_day_routine("guild_rank", update_day)

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            f(...)
        else
            skynet.retpack(f(...))
        end
	end)
end)
