local skynet = require "skynet"
local redis = require "redis"
local snax = require "snax"

local db

function init(conf)
    db = redis.connect(conf)
    local master = snax.queryservice("dbmaster")
    master.req.register_slave(conf, skynet.self(), SERVER_NAME)
end

function exit()
    
end

function response.has(key)
    return db:exists(key)
end

function response.get(key)
    if db:exists(key) then
        return db:get(key)
    end
end

function response.save(key, value)
    db:set(key, value)
end

function response.del(key)
    db:del(key)
end
