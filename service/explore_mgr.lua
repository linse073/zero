local skynet = require "skynet"
local sharedata = require "sharedata"
local util = require "util"

local assert = assert
local string = string

local explore_area = {}
local role_list = {}
local searchdata
local exploredb

local CMD = {}

function CMD.open()
    searchdata = sharedata.query("searchdata")
    for k, v in pairs(searchdata) do
        local explore = skynet.newservice("explore")
        local area = v.stageType * 100 + v.stageId
        skynet.call(explore, "lua", "open", v, area)
        explore_area[area] = explore
    end
    local master = skynet.queryservice("dbmaster")
    exploredb = skynet.call(master, "lua", "get", "exploredb")
    util.dump(skynet.call(exploredb, "lua", "scan", 0))
end

function CMD.get(area)
    return assert(explore_area[area], string.format("No explore area %d.", area))
end

function CMD.get_info(roleid)
end

function CMD.explore(roleid, area)
    CMD.exit(roleid)
    local explore = assert(explore_area[area], string.format("No explore area %d.", area))
    skynet.call(explore, "lua", "explore", roleid)
end

function CMD.quit(roleid)
    local explore = role_list[roleid]
    if explore then
        skynet.call(explore, "lua", "quit", roleid)
    end
    -- TODO: award
end

function CMD.update(roleid, fight_point)
    local explore = role_list[roleid]
    if explore then
        skynet.call(explore, "lua", "update", roleid, fight_point)
    end
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
