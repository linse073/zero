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

