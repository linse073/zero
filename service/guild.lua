local skynet = require "skynet"
local timer = require "timer"

local assert = assert

local info
local guilddb

local CMD = {}

local function save()
end

function CMD.open(i)
    info = i
end

function CMD.active()
    return info.active
end

function CMD.update_rank(rank)
    info.rank = rank
    -- TODO: broadcast
end

function CMD.base_info(roleid)
end

skynet.start(function()
    -- TODO: save routine

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            f(...)
        else
            skynet.retpack(f(...))
        end
	end)
end)
