local skynet = require "skynet"
local timer = require "timer"
local queue = require "skynet.queue"
local sharedata = require "sharedata"

local assert = assert
local string = string
local pairs = pairs
local math = math
local random = math.random
local table = table

local cs = queue()
local explore_status
local data
local rankdb
local rankname
local explore_mgr
local ratio_min
local role_mgr
local rank_count
local role_list = {}

local RAND_FACTOR = 10000
local MAX_ENCOUNTER_RATIO = RAND_FACTOR / 2
local ENCOUNTER_TIME = 5
local ENCOUNTER_RANK = 3

local CMD = {}

local function update()
    local now = floor(skynet.time())
    for k, v in pairs(role_list) do
        if v.status == explore_status.NORMAL then
            local t = now - v.start_time
            if t >= data.searchTime - ENCOUNTER_TIME then
                skynet.call(rankdb, "lua", "zrem", rankname, k)
                rank_count = rank_count - 1
                v.status = explore_status.IDLE
                local agent = skynet.call(role_mgr, "lua", "get", k)
                if agent then
                    skynet.send(agent, "lua", "notify", "update_user", {
                        update={explore={status=v.status}}
                    })
                end
                skynet.call(explore_mgr, "lua", "update_info", k, v)
            else
                if now - v.update_time > = 60 then
                    local ratio = (now - v.time) // 60 * ratio_min
                    if random(RAND_FACTOR) <= ratio then
                        local rank = skynet.call(rankdb, "lua", "zrank", rankname, k)
                        local minr = rank - ENCOUNTER_RANK
                        if minr < 0 then
                            minr = 0
                        end
                        local maxr = rank + ENCOUNTER_RANK
                        if maxr >= rank_count then
                            maxr = rank_count - 1
                        end
                        if maxr ~= minr then
                            local er = skynet.call(rankdb, "lua", "zrange", rankname, minr, maxr)
                            table.remove(er, rank - minr + 1)
                            local tid = er[random(#er)]
                            v.status = explore_status.ENCOUNTER
                            v.tid = tid
                            v.time = now
                            local agent = skynet.call(role_mgr, "lua", "get", k)
                            if agent then
                                skynet.send(agent, "lua", "notify", "update_user", {
                                    update={explore={
                                        status = v.status,
                                        tid = tid,
                                        time = now,
                                        tinfo = skynet.call(role_mgr, "lua", "get_rank_info", tid),
                                    }}
                                })
                            end
                        end
                    end
                    v.update_time = v.update_time + 60
                    skynet.call(explore_mgr, "lua", "update_info", k, v)
                end
            end
        elseif v.status == explore_status.ENCOUNTER then
        elseif v.status == explore_status.IDLE then
        end
    end
end

local function queue_update()
    cs(update)
end

function CMD.open(d, mgr)
    explore_status = sharedata.query("explore_status")
    data = d
    explore_mgr = mgr
    rankname = "explore_" .. d.area
    ratio_min = MAX_ENCOUNTER_RATIO // (d.searchTime - ENCOUNTER_TIME)
    role_mgr = skynet.queryservice("role_mgr")
    local master = skynet.queryservice("dbmaster")
    rankdb = skynet.call(master, "lua", "get", "rankdb")
    skynet.call(rankdb, "lua", "zrem_by_rank", rankname, 0, -1)
    rank_count = 0
    timer.add_second_routine("update_explore", queue_update)
end

function CMD.enter(roleid)
    local info = role_list[roleid]
    if info then
    end
end

function CMD.add(roleid, info)
    skynet.call(rankdb, "lua", "zadd", rankname, -info.fight_point, roleid)
    role_list[roleid] = info
end

function CMD.explore(roleid, fight_point)
    skynet.call(rankdb, "lua", "zadd", rankname, -fight_point, roleid)
    local now = floor(skynet.time())
    local info = {
        fight_point = fight_point,
        area = data.area,
        start_time = now,
        status = explore_status.NORMAL,
        time = now,
        update_time = now,
    }
    role_list[roleid] = info
    skynet.call(explore_mgr, "lua", "update_info", info)
    return {
        area = info.area,
        start_time = now,
        status = info.status,
        time = now,
    }
end

function CMD.quit(roleid)
    local info = role_list[roleid]
    if info then
        role_list[roleid] = nil
        skynet.call(randdb, "lua", "zrem", rankname, roleid)
        if info.status == explore_status.ENCOUNTER then
        else
            -- TODO: award
            info.status = explore_status.FINISH
            skynet.call(explore_mgr, "lua", "update_info", info)
        end
    end
end

function CMD.fight(roleid)
    local info = role_list[roleid]
    if info then
    end
end

function CMD.update(roleid, fight_point)
    local info = role_list[roleid]
    if info then
        skynet.call(rankdb, "lua", "zadd", rankname, -fight_point, roleid)
        info.fight_point = fight_point
        skynet.call(explore_mgr, "lua", "update_info", info)
    end
end

function CMD.shutdown()
    timer.del_second_routine("explore_update")
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
