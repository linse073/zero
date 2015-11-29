local skynet = require "skynet"
local redis = require "redis"

local db

local CMD = {}

function CMD.open(conf, server)
    db = redis.connect(conf)
    local master = skynet.queryservice("dbmaster")
    skynet.call(conf.name, "lua", "register", server, conf.name, skynet.self())
end

function CMD.has(key)
    return db:exists(key)
end

function CMD.get(key)
    if db:exists(key) then
        return db:get(key)
    end
end

function CMD.save(key, value)
    db:set(key, value)
end

function CMD.del(key)
    db:del(key)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
