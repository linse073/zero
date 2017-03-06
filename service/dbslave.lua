local skynet = require "skynet"
local redis = require "redis"

local assert = assert

local db

local CMD = {}
setmetatable(CMD, {
    __index = function(self, key)
        local v = db[key]
        if v then
            local f = function(...)
                return v(db, ...)
            end
            CMD[key] = f
            return f
        end
    end,
})

function CMD.open(conf, name)
    db = redis.connect(conf)
    local master = skynet.queryservice("dbmaster")
    skynet.call(master, "lua", "register", name, skynet.self())
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
