local skynet = require "skynet"
local sharedata = require "sharedata"

local assert = assert
local string = string

local explore_area = {}
local role_list = {}
local searchdata

local CMD = {}

function CMD.get(area)
    return assert(explore_area[area], string.format("No explore area %d.", area))
end

function CMD.explore(roleid, area)
    CMD.exit(roleid)
    explore = assert(explore_area[area], string.format("No explore area %d.", area))
    skynet.call(explore, "lua", "explore", roleid)
end

function CMD.quit(roleid)
    local explore = role_list[roleid]
    if explore then
        skynet.call(explore, "lua", "quit", roleid)
    end
end

skynet.start(function()
    searchdata = sharedata.query("searchdata")
    for k, v in pairs(searchdata) do
        local explore = skynet.newservice("explore")
        skynet.call(explore, "lua", "open", v)
        explore_area[v.stageType * 100 + v.stageId] = explore
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
