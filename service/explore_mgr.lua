local skynet = require "skynet"
local sharedata = require "sharedata"

local assert = assert
local string = string

local explore_area = {}
local role_list = {}

local CMD = {}

function CMD.shutdown()
    for k, v in pairs(explore_area) do
        skynet.call(v, "lua", "shutdown")
    end
end

function CMD.get_explore(area)
    return assert(explore_area[area], string.format("No explore area %d.", area))
end

function CMD.get(roleid)
    return role_list[roleid]
end

function CMD.add(roleid, explore)
    role_list[roleid] = explore
end

function CMD.del(roleid)
    role_list[roleid] = nil
end

skynet.start(function()
    local searchdata = sharedata.query("searchdata")
    for k, v in pairs(searchdata) do
        local explore = skynet.newservice("explore")
        skynet.call(explore, "lua", "open", v, skynet.self())
        explore_area[v.area] = explore
    end

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            f(...)
        else
            skynet.retpack(f(...))
        end
	end)
end)
