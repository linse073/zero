local skynet = require "skynet"
local queue = require "skynet.queue"
local util = require "util"

local rankdb
local rankinfodb
local count
local cs
local math = math
local floor = math.floor

local rank_type = {
    RANK_ARENA = 1,
    RANK_FIGHT_POINT = 2,
}

local CMD = {}

local function check_info(info)
    if skynet.call(rankinfodb, "lua", "has", info.id) then
        return false
    else
        count = count + 1
        info.arena_rank = count
        skynet.call(rankinfodb, "lua", "save", info.id, skynet.packstring(info))
        return true
    end
end

local update_rank = {
    [rank_type.RANK_ARENA] = function(info)
        skynet.call(rankdb, "lua", "zadd", "arena", info.arena_rank, info.id)
    end,
    [rank_type.RANK_FIGHT_POINT] = function(info)
        skynet.call(rankdb, "lua", "zadd", "fight_point", -info.fight_point, info.id)
    end,
}

local query_rank = {
    [rank_type.RANK_ARENA] = function(roleid, arena_rank)
        local range = {}
        if arena_rank < 4 then
            local temp = skynet.call(rankdb, "lua", "zrange", "arena", 0, 3)
            temp[arena_rank] = nil
            for k, v in pairs(temp) do
                local info = skynet.unpack(skynet.call(rankinfodb, "lua", "get", v))
                info.rank = k + 1
                range[#range+1] = info
            end
        else
            local rank = arena_rank - 1
            for i = 1, 3 do
                rank = (rank * (random(199) + 800)) // 1000
                local id = skynet.call(rankdb, "lua", "zrange", "arena", rank, rank)[1]
                local info = skynet.unpack(skynet.call(rankinfodb, "lua", "get", id))
                info.rank = rank + 1
                range[#range+1] = info
            end
        end
        -- TODO: test range
        util.dump(range)
    end,
    [rank_type.RANK_FIGHT_POINT] = function(roleid, fight_point)
    end,
}

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
end

function CMD.add(info)
    if cs(check_info, info) then
        -- NOTICE: count will be save as float in redis
        skynet.call(rankinfodb, "lua", "save", "count", count) 
    else
        local arena_rank = skynet.call(rankdb, "lua", "zrank", "arena", info.id)
        if arena_rank then
            info.arena_rank = arena_rank + 1
        end
        skynet.call(rankinfodb, "lua", "save", info.id, skynet.packstring(info))
    end
    for k, v in ipairs(update_rank) do
        v(info)
    end
    return info.arena_rank
end

function CMD.update(info, rank_type)
    if rank_type then
        update_rank[rank_type](info)
    end
    skynet.call(rankinfodb, "lua", "save", info.id, skynet.packstring(info))
end

function CMD.query(rank_type, roleid, value)
    query_rank[rank_type](roleid, value)
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
