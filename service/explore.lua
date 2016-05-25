local skynet = require "skynet"
local timer = require "timer"

local assert = assert
local string = string

local data
local area
local rankdb
local rankname

local CMD = {}

local function update()
    local now = skynet.time()
end

function CMD.open(d, a)
    data = d
    area = a
    rankname = "explore_" .. a
    timer.add_second_routine("update_explore", update)
    local master = skynet.queryservice("dbmaster")
    rankdb = skynet.call(master, "lua", "get", "rankdb")
end

function CMD.explore(roleid, fight_point)
    skynet.call(rankdb, "lua", "zadd", rankname, -fight_point, roleid)
end

function CMD.quit(roleid)
    skynet.call(randdb, "lua", "zrem", rankname, roleid)
end

function CMD.update(roleid, fight_point)
    skynet.call(rankdb, "lua", "zadd", rankname, -fight_point, roleid)
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
