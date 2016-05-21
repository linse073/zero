local skynet = require "skynet"
local sharedata = require "sharedata"

local assert = assert
local string = string

local explore_area = {}
local searchdata

local CMD = {}

function CMD.get(area)
    local address = explore_area[area]
    assert(address, string.format("No explore area %d.", area))
    return address
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
