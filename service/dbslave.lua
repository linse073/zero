local skynet = require "skynet"
local redis = require "redis"
local snax = require "snax"

local db

function init(conf, handle, typename)
    db = redis.connect(conf)
    local master = snax.bind(handle, typename)
    master.req.register_slave(conf, skynet.self(), SERVER_NAME)
end

function exit()
    
end

