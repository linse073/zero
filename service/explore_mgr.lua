local skynet = require "skynet"
local sharedata = require "sharedata"

local assert = assert
local string = string
local pairs = pairs

local explore_area = {}
local role_list = {}
local area_guild = {}
local guild = {}

local CMD = {}

function CMD.shutdown()
    for k, v in pairs(explore_area) do
        skynet.call(v, "lua", "shutdown")
    end
end

function CMD.get_explore(area)
    return explore_area[area]
end

function CMD.get_all_explore()
    return explore_area
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

function CMD.occupy_guild(area, gid)
    local og = area_guild[area]
    if og then
        guild[og][area] = nil
    end
    area_guild[area] = gid
    if gid then
        local a = guild[gid]
        if not a then
            a = {}
            guild[gid] = a
        end
        a[area] = area
    end
end

function CMD.area_guild()
    return area_guild
end

function CMD.occupy_area(id)
    return guild[id]
end

skynet.start(function()
    local searchdata = sharedata.query("searchdata")
    local bonusdata = sharedata.query("bonusdata")
    for k, v in pairs(searchdata) do
        local bonus = assert(bonusdata[v.bonusId], string.format("No bonus data %d.", v.bonusId))
        local explore = skynet.newservice("explore")
        skynet.call(explore, "lua", "open", v, bonus, skynet.self())
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
