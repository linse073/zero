local skynet = require "skynet"
local timer = require "timer"
local func = require "func"
local queue = require "skynet.queue"

local assert = assert
local string = string

local explore_status = func.explore_status
local cs = queue()
local data
local area
local rankdb
local rankname
local explore_mgr
local role_mgr
local role_list = {}

local CMD = {}

local function award(info)
    
end

local function update()
    local now = skynet.time()
    -- TODO: encounter logic
end

function CMD.open(d, a, mgr)
    data = d
    area = a
    explore_mgr = mgr
    role_mgr = skynet.queryservice("role_mgr")
    rankname = "explore_" .. a
    timer.add_second_routine("update_explore", update)
    local master = skynet.queryservice("dbmaster")
    rankdb = skynet.call(master, "lua", "get", "rankdb")
    skynet.call(rankdb, "lua", "zrem_by_rank", rankname, 0, -1)
end

function CMD.get_info(roleid)
    return role_list[roleid]
end

function CMD.add(info)
    skynet.call(rankdb, "lua", "zadd", rankname, -info.fight_point, info.roleid)
    role_list[roleid] = info
end

function CMD.explore(roleid, area, fight_point)
    skynet.call(rankdb, "lua", "zadd", rankname, -fight_point, roleid)
    local now = floor(skynet.time())
    local info = {
        roleid = roleid,
        fight_point = fight_point,
        area = area,
        start_time = now,
        status = explore_status.EXPLORE_NORMAL,
        time = now,
    }
    role_list[roleid] = info
    skynet.call(explore_mgr, "lua", "update_info", info)
end

function CMD.quit(roleid)
    local info = role_list[roleid]
    if info then
        role_list[roleid] = nil
        skynet.call(randdb, "lua", "zrem", rankname, roleid)
        if info.status == explore_status.EXPLORE_ENCOUNTER then
        else
            -- TODO: award
            info.status = explore_status.EXPLORE_FINISH
            skynet.call(explore_mgr, "lua", "update_info", info)
        end
    end
end

function CMD.fight(roleid)
    
end

function CMD.update(roleid, fight_point)
    local info = role_list[roleid]
    if info then
        skynet.call(rankdb, "lua", "zadd", rankname, -fight_point, roleid)
        info.fight_point = fight_point
        skynet.call(explore_mgr, "lua", "update_info", info)
    end
end

function CMD.second_routine(key)
    timer.call_second_routine(key)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            cs(f, ...)
        else
            skynet.retpack(cs(f, ...))
        end
	end)
end)
