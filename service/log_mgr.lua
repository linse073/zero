local skynet = require "skynet"

local assert = assert
local string = string

local log_list = {}

local CMD = {}

function CMD.open(conf)
    for k, v in ipairs(conf.name) do
        local log = skynet.newservice("log")
        skynet.call(log, "lua", "open", {host=conf.host}, v)
        log_list[v] = log
    end
    skynet.call(log_list["ioscharge"], "lua", "ensureIndex", {"transaction_id", unique=true})
end

function CMD.get(name)
    return assert(log_list[name], string.format("No log server %s.", name))
end

function CMD.get_all()
    return log_list
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
