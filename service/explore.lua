local skynet = require "skynet"
local timer = require "timer"
local queue = require "skynet.queue"
local sharedata = require "sharedata"

local assert = assert
local string = string
local pairs = pairs
local math = math
local random = math.random
local floor = math.floor
local table = table
local tonumber = tonumber

local cs = queue()
local explore_status
local explore_reason
local data
local rankdb
local rankname
local explore_mgr
local save_explore
local ratio_min
local role_mgr
local rank_count
local role_list = {}

local RAND_FACTOR = 10000
local MAX_ENCOUNTER_RATIO = RAND_FACTOR / 2
local ENCOUNTER_MIN = 5
local ENCOUNTER_SECOND = ENCOUNTER_MIN * 60
local ENCOUNTER_RANK = 3
local BONUS_TIME = 120
local UPDATE_TIME = 60

local CMD = {}

local function encounter(info, t, tid)
    info.status = explore_status.ENCOUNTER
    info.time = t
    info.tid = tid
    info.ack = 0
    info.tack = 0
    local agent = skynet.call(role_mgr, "lua", "get", info.roleid)
    if agent then
        skynet.send(agent, "lua", "notify", "update_user", {update={explore={
            status = info.status,
            time = t,
            tinfo = skynet.call(role_mgr, "lua", "get_rank_info", tid),
            ack = info.ack,
            tack = info.tack,
        }}})
    end
end

local function battle(info, tinfo)
    local ts = info.fight_point + tinfo.fight_point
    local ms = ts / 10
    local ds = info.fight_point - tinfo.fight_point
    if ds > ms then
        return true
    elseif ds < -ms then
        return false
    else
        local rnum = random(ts)
        if rnum <= info.fight_point then
            return true
        else
            return false
        end
    end
end

local function win(t, info, tinfo)
    local dm = (t - tinfo.start_time) // 60
    local money = data.money * dm // data.searchTime
    info.money = info.money + money * data.lootRatio // RAND_FACTOR
    local num = dm // BONUS_TIME
    for i = 1, num do
        local rnum = random(RAND_FACTOR)
        if rnum <= data.lootRatio then
            info.bonus = info.bonus + 1
        end
    end
    local dt = t - info.start_time
    if dt >= data.searchSecond - ENCOUNTER_SECOND then
        info.status = explore_status.IDLE
    else
        info.status = explore_status.NORMAL
        skynet.call(rankdb, "lua", "zadd", rankname, -info.fight_point, info.roleid)
        rank_count = rank_count + 1
    end
    info.time = t
    info.win = info.win + 1
    local agent = skynet.call(role_mgr, "lua", "get", info.roleid)
    if agent then
        skynet.send(agent, "lua", "notify", "update_user", {update={explore={
            status = info.status,
            time = t,
        }}})
    end
    skynet.call(save_explore, "lua", "update", info.roleid, info)
    tinfo.reason = explore_reason.FAIL
    info.fail = info.fail + 1
    local tagent = skynet.call(role_mgr, "lua", "get", tinfo.roleid)
    if tagent then
        tinfo.status = explore_status.FINISH
        skynet.call(tagent, "lua", "explore_award", 
            {status=tinfo.status, reason=tinfo.reason}, 
            {money=tinfo.money, bonus=data.bonusId, num=tinfo.bonus, win=tinfo.win, fail=tinfo.fail})
    else
        tinfo.status = explore_status.DONE
    end
    skynet.call(save_explore, "lua", "update", tinfo.roleid, tinfo)
end

local function update()
    local now = floor(skynet.time())
    for k, v in pairs(role_list) do
        if v.status == explore_status.NORMAL then
            local t = now - v.start_time
            if t >= data.searchSecond - ENCOUNTER_SECOND then
                skynet.call(rankdb, "lua", "zrem", rankname, k)
                rank_count = rank_count - 1
                v.status = explore_status.IDLE
                local agent = skynet.call(role_mgr, "lua", "get", k)
                if agent then
                    skynet.send(agent, "lua", "notify", "update_user", {update={explore={
                        status = v.status,
                    }}})
                end
                skynet.call(save_explore, "lua", "update", k, v)
            elseif now - v.update_time >= UPDATE_TIME then
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
                        local tid = tonumber(er[random(#er)])
                        skynet.call(rankdb, "lua", "zrem", rankname, k)
                        encounter(v, now, tid)
                        local tinfo = role_list[tid]
                        skynet.call(rankdb, "lua", "zrem", rankname, tid)
                        encounter(tinfo, now, k)
                        rank_count = rank_count - 2
                        skynet.call(save_explore, "lua", "update", tid, tinfo)
                    end
                end
                v.update_time = v.update_time + UPDATE_TIME
                skynet.call(save_explore, "lua", "update", k, v)
            end
        elseif v.status == explore_status.ENCOUNTER then
            local t = now - v.time
            if t >= ENCOUNTER_SECOND then
                local tinfo = role_list[v.tid]
                if battle(v, tinfo) then
                    win(now, v, tinfo)
                else
                    win(now, tinfo, v)
                end
            end
        elseif v.status == explore_status.IDLE then
            local t = now - v.start_time
            if t >= data.searchSecond then
                v.money = v.money + data.money
                v.bonus = v.bonus + data.searchTime // BONUS_TIME
                v.reason = explore_reason.NORMAL
                local agent = skynet.call(role_mgr, "lua", "get", k)
                if agent then
                    v.status = explore_status.FINISH
                    skynet.call(agent, "lua", "explore_award", 
                        {status=v.status, reason=v.reason},
                        {money=v.money, bonus=data.bonusId, num=v.bonus, win=v.win, fail=v.fail})
                else
                    v.status = explore_status.DONE
                end
                skynet.call(save_explore, "lua", "update", k, v)
            end
        end
    end
end

function CMD.open(d, mgr)
    explore_status = sharedata.query("explore_status")
    explore_reason = sharedata.query("explore_reason")
    data = d
    explore_mgr = mgr
    rankname = "explore_" .. d.area
    ratio_min = MAX_ENCOUNTER_RATIO // (d.searchTime - ENCOUNTER_MIN)
    save_explore = skynet.queryservice("save_explore")
    role_mgr = skynet.queryservice("role_mgr")
    local master = skynet.queryservice("dbmaster")
    rankdb = skynet.call(master, "lua", "get", "rankdb")
    skynet.call(rankdb, "lua", "zrem_by_rank", rankname, 0, -1)
    rank_count = 0
    timer.add_second_routine("update_explore", update)
end

function CMD.enter(roleid)
    local info = role_list[roleid]
    if info then
        local award
        if info.status == explore_status.DONE then
            info.status = explore_status.FINISH
            skynet.call(save_explore, "lua", "update", roleid, info)
            award = {
                money = info.money,
                bonus = data.bonusId,
                num = info.bonus,
                win = info.win,
                fail = info.fail,
            }
        end
        local ti
        if info.tid then
            ti = skynet.call(role_mgr, "lua", "get_rank_info", info.tid)
        end
        return {
            area = info.area,
            start_time = info.start_time,
            status = info.status,
            time = info.time,
            tinfo = ti,
            ack = info.ack,
            tack = info.tack,
            reason = info.reason,
        }, award
    end
end

function CMD.add(info)
    if not role_list[info.roleid] then
        if info.status == explore_status.NORMAL then
            skynet.call(rankdb, "lua", "zadd", rankname, -info.fight_point, info.roleid)
            rank_count = rank_count + 1
        end
        role_list[info.roleid] = info
        skynet.call(explore_mgr, "lua", "add", info.roleid, skynet.self())
    end
end

function CMD.explore(roleid, fight_point)
    skynet.call(rankdb, "lua", "zadd", rankname, -fight_point, roleid)
    rank_count = rank_count + 1
    local now = floor(skynet.time())
    local info = {
        roleid = roleid,
        fight_point = fight_point,
        area = data.area,
        start_time = now,
        status = explore_status.NORMAL,
        time = now,
        update_time = now,
        money = 0,
        bonus = 0,
        win = 0,
        fail = 0,
    }
    role_list[roleid] = info
    skynet.call(explore_mgr, "lua", "add", roleid, skynet.self())
    skynet.call(save_explore, "lua", "update", roleid, info)
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
        if info.status == explore_status.ENCOUNTER then
            local t = floor(skynet.time())
            local tinfo = role_list[info.tid]
            local dm = (t - info.start_time) // 60
            local money = data.money * dm // data.searchTime
            info.money = info.money + money * data.escapeKeepRatio // RAND_FACTOR
            tinfo.money = tinfo.money + money * data.escapeLootRatio // RAND_FACTOR
            local num = dm // BONUS_TIME
            for i = 1, num do
                local rnum = random(RAND_FACTOR)
                if rnum <= data.escapeKeepRatio then
                    info.bonus = info.bonus + 1
                else
                    local tnum = random(RAND_FACTOR)
                    if tnum <= data.escapeLootRatio then
                        tinfo.bonus = tinfo.bonus + 1
                    end
                end
            end
            info.status = explore_status.FINISH
            info.reason = explore_reason.ESCAPE
            info.ack = 2
            skynet.call(save_explore, "lua", "update", roleid, info)
            local dt = t - tinfo.start_time
            if dt >= data.searchSecond - ENCOUNTER_SECOND then
                tinfo.status = explore_status.IDLE
            else
                tinfo.status = explore_status.NORMAL
                skynet.call(rankdb, "lua", "zadd", rankname, -tinfo.fight_point, tinfo.roleid)
                rank_count = rank_count + 1
            end
            tinfo.time = t
            tinfo.tack = 2
            local tagent = skynet.call(role_mgr, "lua", "get", tinfo.roleid)
            if tagent then
                skynet.send(tagent, "lua", "notify", "update_user", {update={explore={
                    status = tinfo.status,
                    time = t,
                    tack = tinfo.tack,
                }}})
            end
            skynet.call(save_explore, "lua", "update", tinfo.roleid, tinfo)
            return {status=info.status, ack=info.ack, reason=info.reason}, 
            {money=info.money, bonus=data.bonusId, num=info.bonus, win=info.win, fail=info.fail}
        elseif info.status == explore_status.DONE then
            info.status = explore_status.FINISH
            skynet.call(save_explore, "lua", "update", roleid, info)
            return {status=info.status},
            {money=info.money, bonus=data.bonusId, num=info.bonus, win=info.win, fail=info.fail}
        elseif info.status == explore_status.NORMAL or info.status == explore_status.IDLE then
            if info.status == explore_status.NORMAL then
                skynet.call(rankdb, "lua", "zrem", rankname, roleid)
                rank_count = rank_count - 1
            end
            local t = floor(skynet.time())
            local dm = (t - info.start_time) // 60
            info.money = info.money + data.money * dm // data.searchTime
            info.bonus = info.bonus + dm // BONUS_TIME
            info.status = explore_status.FINISH
            info.reason = explore_reason.QUIT
            skynet.call(save_explore, "lua", "update", roleid, info)
            return {status=info.status, reason=info.reason},
            {money=info.money, bonus=data.bonusId, num=info.bonus, win=info.win, fail=info.fail}
        end
    end
end

function CMD.confirm(roleid)
    local info = role_list[roleid]
    if info and info.status == explore_status.FINISH then
        role_list[roleid] = nil
        skynet.call(save_explore, "lua", "update", roleid, false)
        skynet.call(explore_mgr, "lua", "del", roleid)
        return true
    end
end

function CMD.fight(roleid)
    local info = role_list[roleid]
    if info and info.status == explore_status.ENCOUNTER then
        info.ack = 1
        skynet.call(save_explore, "lua", "update", roleid, info)
        local tinfo = role_list[info.tid]
        tinfo.tack = 1
        local tagent = skynet.call(role_mgr, "lua", "get", info.tid)
        if tagent then
            skynet.send(tagent, "lua", "notify", "update_user", {update={explore={
                tack = tinfo.tack
            }}})
        end
        skynet.call(save_explore, "lua", "update", info.tid, tinfo)
        return {ack=info.ack}
    end
end

function CMD.update(roleid, fight_point)
    local info = role_list[roleid]
    if info then
        if info.status == explore_status.NORMAL then
            skynet.call(rankdb, "lua", "zadd", rankname, -fight_point, roleid)
        end
        info.fight_point = fight_point
        skynet.call(save_explore, "lua", "update", roleid, info)
        return true
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
