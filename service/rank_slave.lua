local skynet = require "skynet"
local queue = require "skynet.queue"

local assert = assert

local rank_name = ...

local cs = queue()
local rankdb
local count

local CMD = {}

function CMD.add(roleid, value)
    local r = skynet.call(rankdb, "lua", "zrank", rank_name, roleid)
    if not r then
        count = count + 1
        skynet.call(rankdb, "lua", "zadd", rank_name, -value, roleid)
    end
end

function CMD.update(roleid, value)
    skynet.call(rankdb, "lua", "zadd", rank_name, -value, roleid)
end

function CMD.query(roleid, min, max)
    local cr = skynet.call(rankdb, "lua", "zrank", rank_name, roleid)
    local score = skynet.call(rankdb, "lua", "zscore", rank_name, roleid)
    local r = skynet.call(rankdb, "lua", "zrange", rank_name, min, max, "WITHSCORES")
    return cr, score, r
end

skynet.start(function()
    local master = skynet.queryservice("dbmaster")
    rankdb = skynet.call(master, "lua", "get", "rankdb")
    count = skynet.call(rankdb, "lua", "zcard", rank_name)

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            cs(f, ...)
        else
            skynet.retpack(cs(f, ...))
        end
	end)
end)
