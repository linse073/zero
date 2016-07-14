local skynet = require "skynet"
local redis = require "redis"

local db

local CMD = {}

function CMD.open(conf)
    db = redis.connect(conf)
    local master = skynet.queryservice("dbmaster")
    skynet.call(master, "lua", "register", conf.name, skynet.self())
end

function CMD.has(key)
    return db:exists(key)
end

function CMD.get(key)
    -- if db:exists(key) then
        return db:get(key)
    -- end
end

function CMD.save(key, value)
    db:set(key, value)
end

function CMD.del(key)
    db:del(key)
end

function CMD.zadd(rt, ...)
    db:zadd(rt, ...)
end

function CMD.zrem(rt, key)
    db:zrem(rt, key)
end

function CMD.zrem_by_rank(rt, r1, r2)
    db:zremrangebyrank(rt, r1, r2)
end

function CMD.zrange(rt, r1, r2)
    return db:zrange(rt, r1, r2)
end

function CMD.zrank(rt, key)
    return db:zrank(rt, key)
end

function CMD.zcount(rt, r1, r2)
    if not r1 then
        r1 = "-inf"
    end
    if not r2 then
        r2 = "+inf"
    end
    return db:zcount(rt, r1, r2)
end

function CMD.scan(i)
    return db:scan(i)
end

function CMD.lpush(key, value)
    db:lpush(key, value)
end

function CMD.rpush(key, value)
    db:rpush(key, value)
end

function CMD.lrange(key, r1, r2)
    return db:lrange(key, r1, r2)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
