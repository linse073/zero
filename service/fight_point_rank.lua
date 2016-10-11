local skynet = require "skynet"
local queue = require "skynet.queue"
local util = require "util"

local math = math
local random = math.random
local assert = assert
local string = string
local table = table
local tonumber = tonumber
local merge = util.merge
local ipairs = ipairs

local cs = queue()
local rankdb
local count

local CMD = {}

local function random_forward(user_rank, bc, rank_count)
    local r = {}
    if bc <= rank_count then
        for i = 1, bc do
            r[i] = user_rank - i
        end
    else
        local sr = user_rank + 1
        local mc
        if sr <= 25 then
            mc = rank_count * 5
        else
            mc = sr // 5
        end
        if mc < rank_count then
            mc = rank_count
        elseif mc > bc then
            mc = bc
        end
        for i = 1, rank_count do
            local l = random(mc - i + 1)
            local ti
            for k, v in ipairs(r) do
                if v <= l then
                    l = l + 1
                else
                    ti = k
                    break
                end
            end
            if ti then
                table.insert(r, ti, l)
            else
                r[#r+1] = l
            end
        end
        for k, v in ipairs(r) do
            r[k] = user_rank - v
        end
    end
    return r
end

local function random_backward(user_rank, bc, rank_count)
    local r = {}
    if bc <= rank_count then
        for i = 1, bc do
            r[i] = user_rank + i
        end
    else
        local sr = user_rank + 1
        local mc
        if sr <= 25 then
            mc = rank_count * 5
        else
            mc = sr * 16 // 10
        end
        if mc < rank_count then
            mc = rank_count
        elseif mc > bc then
            mc = bc
        end
        for i = 1, rank_count do
            local l = random(mc - i + 1)
            local ti
            for k, v in ipairs(r) do
                if v <= l then
                    l = l + 1
                else
                    ti = k
                    break
                end
            end
            if ti then
                table.insert(r, ti, l)
            else
                r[#r+1] = l
            end
        end
        for k, v in ipairs(r) do
            r[k] = user_rank + v
        end
    end
    return r
end

local function query_fight_point(user_rank)
    local r
    local bc = count - user_rank - 1
    if user_rank == 0 then
        r = random_backward(user_rank, bc, 9)
    else
        r = random_backward(user_rank, bc, 8)
        merge(r, random_forward(user_rank, user_rank, 9 - #r))
        table.sort(r)
    end
    return r
end

function CMD.add(roleid, fight_point)
    local fr = skynet.call(rankdb, "lua", "zrank", "fight_point", roleid)
    if not fr then
        count = count + 1
        skynet.call(rankdb, "lua", "zadd", "fight_point", -fight_point, roleid)
    end
end

function CMD.update(roleid, fight_point)
    skynet.call(rankdb, "lua", "zadd", "fight_point", -fight_point, roleid)
end

function CMD.query(roleid)
    local cr = skynet.call(rankdb, "lua", "zrank", "fight_point", roleid)
    if cr then
        local rank = query_fight_point(cr)
        local i = 1
        local l = #rank
        local range = {}
        while i <= l do
            local j = i + 1
            while j <= l and rank[j] - rank[j - 1] < 10 do
                j = j + 1
            end
            local m = rank[i]
            local r = skynet.call(rankdb, "lua", "zrange", "fight_point", m, rank[j - 1])
            for k = i, j - 1 do
                range[#range + 1] = {tonumber(r[rank[k] - m + 1]), rank[k]}
            end
            i = j
        end
        return cr, range
    end
end

function CMD.batch_get(r)
    local cr = {}
    for k, v in ipairs(r) do
        cr[v] = skynet.call(rankdb, "lua", "zrank", "fight_point", v)
    end
    return cr
end

skynet.start(function()
    local master = skynet.queryservice("dbmaster")
    rankdb = skynet.call(master, "lua", "get", "rankdb")
    count = skynet.call(rankdb, "lua", "zcard", "fight_point")

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            cs(f, ...)
        else
            skynet.retpack(cs(f, ...))
        end
	end)
end)
