local skynet = require "skynet"
local queue = require "skynet.queue"

local rankdb
local rankinfodb
local count
local cs
local math = math
local floor = math.floor
local assert = assert
local string = string

local rank_type = {
    RANK_ARENA = 1,
    RANK_FIGHT_POINT = 2,
}

local CMD = {}

local update_rank = {
    [rank_type.RANK_ARENA] = function(info)
        skynet.call(rankdb, "lua", "zadd", "arena", info.arena_rank, info.id)
    end,
    [rank_type.RANK_FIGHT_POINT] = function(info)
        skynet.call(rankdb, "lua", "zadd", "fight_point", -info.fight_point, info.id)
    end,
}

local get_rank = {
    [rank_type.RANK_ARENA] = function(roleid)
        return skynet.call(rankdb, "lua", "zrank", "arena", roleid), count
    end,
    [rank_type.RANK_FIGHT_POINT] = function(roleid)
        return skynet.call(rankdb, "lua", "zrank", "fight_point", roleid)
    end,
}

local get_range = {
    [rank_type.RANK_ARENA] = function(r1, r2)
        return skynet.call(rankdb, "lua", "zrange", "arena", r1, r2)
    end,
    [rank_type.RANK_FIGHT_POINT] = function(r1, r2)
        return skynet.call(rankdb, "lua", "zrange", "fight_point", r1, r2)
    end,
}

local function add(info)
    local i = skynet.unpack(skynet.call(rankinfodb, "lua", "get", info.id))
    if i then
        info.arena_rank = i.arena_rank
    else
        count = count + 1
        info.arena_rank = count
        -- NOTICE: count will be save as float in redis
        skynet.call(rankinfodb, "lua", "save", "count", count) 
    end
    skynet.call(rankinfodb, "lua", "save", info.id, skynet.packstring(info))
    for k, v in ipairs(update_rank) do
        v(info)
    end
end

local function update(info, rt)
    if rt then
        update_rank[rt](info)
    end
    skynet.call(rankinfodb, "lua", "save", info.id, skynet.packstring(info))
end

local function update_arena(info1, info2)
    skynet.call(rankdb, "lua", "zadd", "arena", info1.arena_rank, info1.id, info2.arena_rank, info2.id)
    skynet.call(rankinfodb, "lua", "save", info1.id, skynet.packstring(info1))
    skynet.call(rankinfodb, "lua", "save", info2.id, skynet.packstring(info2))
end

local function check_rank()
    local acount = skynet.call(rankdb, "lua", "zcount", "arena")
    assert(acount==count, string.format("Error arena count %d, info count %d.", acount, count))
    local fcount = skynet.call(rankdb, "lua", "zcount", "fight_point")
    assert(fcount==count, string.format("Error fight_point count %d, info count %d.", fcount, count))
end

function CMD.open()
    cs = queue()
    local master = skynet.queryservice("dbmaster")
    rankdb = skynet.call(master, "lua", "get", "rankdb")
    rankinfodb = skynet.call(master, "lua", "get", "rankinfodb")
    count = skynet.call(rankinfodb, "lua", "get", "count")
    if count then
        count = floor(count)
    else
        count = 0
    end
    check_rank()
end

function CMD.add(info)
    cs(add, info)
    return info.arena_rank
end

function CMD.update(info, rt)
    cs(update, info, rt)
end

function CMD.update_arena(info1, info2)
    cs(update_arena, info1, info2)
end

function CMD.get(rt, roleid)
    return get_rank[rt](roleid)
end

function CMD.query(rt, rank)
    local fn = get_range[rt]
    local i = 1
    local l = #rank
    local range = {}
    while i <= l do
        local j = i + 1
        while j <= l and rank[j] - rank[j - 1] < 10 do
            j = j + 1
        end
        local m = rank[i]
        local r = fn(m, rank[j - 1])
        for k = i, j - 1 do
            local nr = rank[k]
            -- NOTICE: if update in query time, it could be user self
            local info = skynet.unpack(skynet.call(rankinfodb, "lua", "get", r[nr - m + 1]))
            info.rank = nr + 1
            range[#range + 1] = info
        end
        i = j
    end
    return range
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
