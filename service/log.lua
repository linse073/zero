local skynet = require "skynet"
local mongo = require "mongo"
local util = require "util"

local assert = assert

local CMD = {}

function CMD.open(conf, name)
    local d = mongo.client({host=conf.host})
    util.cmd_wrap(CMD, d.log[name])
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
