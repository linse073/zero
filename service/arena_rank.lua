local skynet = require "skynet"
local queue = require "skynet.queue"

local math = math
local random = math.random
local assert = assert
local tonumber = tonumber
local string = string
local table = table

local cs = queue()
local rankdb
local count

local CMD = {}

local max_arena_rank = 999
local function query_arena(user_rank)
    local r = {}
    if user_rank <= 3 then
        local c = 4
        if c > count then
            c = count
        end
        for i = 1, c do
            r[i] = i - 1
        end
        table.remove(r, user_rank + 1)
    else
        local nr = user_rank
        if nr > max_arena_rank then
            nr = max_arena_rank
        end
        for i = 1, 3 do
            nr = (nr * (random(199) + 800)) // 1000
            r[i] = nr
        end
        table.sort(r)
    end
    return r
end

function CMD.add(roleid)
    local ar = skynet.call(rankdb, "lua", "zrank", "arena", roleid)
    if not ar then
        ar = count
        count = count + 1
        skynet.call(rankdb, "lua", "zadd", "arena", count, roleid)
    end
    return ar + 1
end

function CMD.update(id1, id2)
    local rank1 = skynet.call(rankdb, "lua", "zrank", "arena", id1)
    local rank2 = skynet.call(rankdb, "lua", "zrank", "arena", id2)
    if rank1 > rank2 then
       skynet.call(rankdb, "lua", "zadd", "arena", rank2, id1, rank1, id2)
       return rank2
    end
end

function CMD.query(roleid)
    local cr = skynet.call(rankdb, "lua", "zrank", "arena", roleid)
    if cr then
        local rank = query_arena(cr)
        local i = 1
        local l = #rank
        local range = {}
        while i <= l do
            local j = i + 1
            while j <= l and rank[j] - rank[j - 1] < 10 do
                j = j + 1
            end
            local m = rank[i]
            local r = skynet.call(rankdb, "lua", "zrange", "arena", m, rank[j - 1])
            for k = i, j - 1 do
                range[#range + 1] = {tonumber(r[rank[k] - m + 1]), rank[k]}
            end
            i = j
        end
        return cr, range
    end
end

function CMD.get(rank)
    local r = skynet.call(rankdb, "lua", "zrange", "arena", rank, rank)
    return tonumber(r[1])
end

skynet.start(function()
    local master = skynet.queryservice("dbmaster")
    rankdb = skynet.call(master, "lua", "get", "rankdb")
    count = skynet.call(rankdb, "lua", "zcard", "arena")

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            cs(f, ...)
        else
            skynet.retpack(cs(f, ...))
        end
	end)
end)
