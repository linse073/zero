local skynet = require "skynet"
local queue = require " skynet.queue"

local rankdb
local rankinfodb
local count
local cs

local CMD = {}

local function check_info(info)
    if skynet.call(rankinfodb, "lua", "has", info.id) then
        return false
    else
        count = count + 1
        info.rank = count
        skynet.call(rankinfodb, "lua", "save", info.id, skynet.packstring(info))
        return true
    end
end

local update_rank = {
    arena = function(info)
        skynet.call(rankdb, "lua", "zadd", "arena", info.arena_rank, info.id)
    end,
    fight_point = function(info)
        skynet.call(rankdb, "lua", "zadd", "fight_point", -info.fight_point, info.id)
    end,
}

function CMD.open()
    cs = queue()
    local master = skynet.queryservice("dbmaster")
    rankdb = skynet.call(master, "lua", "get", "rankdb")
    rankinfodb = skynet.call(master, "lua", "get", "rankinfodb")
    count = skynet.call(rankinfodb, "lua", "get", "count")
    if not count then
        count = 0
    end
end

function CMD.add(info)
    if cs(check_info, info) then
        skynet.call(rankinfodb, "lua", "save", "count", count)
    else
        skynet.call(rankinfodb, "lua", "save", info.id, skynet.packstring(info))
    end
    for k, v in pairs(update_rank) do
        v(info)
    end
    return info.arena_rank
end

function CMD.update(info, rank)
    if rank then
        update_rank[rank](info)
    end
    skynet.call(rankinfodb, "lua", "save", info.id, skynet.packstring(info))
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
