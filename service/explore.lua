local skynet = require "skynet"
local timer = require "timer"
local queue = require "skynet.queue"
local sharedata = require "sharedata"
local new_rand = require "random"
local func = require "func"

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
local bonus_data
local rankdb
local rankname
local explore_mgr
local offline_mgr
local save_explore
local ratio_min
local role_mgr
local task_rank
local guild_mgr
local rank_count
local occupy_guild
local guild = {}
local guild_rank = {}
local role_list = {}

local RAND_FACTOR = 10000
local MAX_ENCOUNTER_RATIO = RAND_FACTOR / 2
local ENCOUNTER_MIN = 5
local ENCOUNTER_SECOND = ENCOUNTER_MIN * 60
local ENCOUNTER_RANK = 3
local BONUS_TIME = 120 * 60
local UPDATE_TIME = 60
local WEEK_TASK_LEVEL = 25

local MONEY_ITEM = 3000005271
local RMB_ITEM = 3000012271
local EXP_ITEM = 3000024271
local SP_ITEM = 3000031271

local MAIL_TYPE_EXPLORE = 3

local explore_title
local explore_win
local explore_fail
local explore_normal
local explore_escape
local explore_quit

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

local function bonus_item(ri, award)
    local itemid = ri.item
    local idata = ri.data
    if idata then
        award[idata.id] = (award[idata.id] or 0) + ri.num
    else
        if itemid then
            award[itemid] = (award[itemid] or 0) + ri.num
        else
            award[MONEY_ITEM] = (award[MONEY_ITEM] or 0) + ri.num
        end
    end
end

local function get_bonus(bonus, award, prof)
    local rand_item = {}
    for i = 1, bonus.rand_num do
        rand_item[i] = func.rand_bonus(bonus.data, prof)
    end
    if bonus.num then
        if type(bonus.num) == "table" then
            for k1, v1 in ipairs(bonus.num) do
                bonus_item(rand_item[v1], award)
            end
        else
            for i = 1, bonus.num do
                bonus_item(rand_item[i], award)
            end
        end
    else
        for k1, v1 in ipairs(rand_item) do
            bonus_item(v1, award)
        end
    end
end

local function mail_bonus(money, num, exp, sp, t, prof)
    local award = {}
    if money > 0 then
        award[MONEY_ITEM] = money
    end
    if exp > 0 then
        award[EXP_ITEM] = exp
    end
    if sp > 0 then
        award[SP_ITEM] = sp
    end
    local m = {
        type = MAIL_TYPE_EXPLORE,
        time = t,
        title = explore_title,
    }
    if num > 0 then
        new_rand.init(t)
        get_bonus({rand_num=num, data=bonus_data}, award, prof)
    end
    local item = {}
    for k, v in pairs(award) do
        item[#item+1] = {
            itemid = k,
            num = v,
        }
    end
    m.item_info = item
    return m
end

local function win(t, info, tinfo)
    local tdt = t - tinfo.start_time
    local money = data.money * tdt // 3600
    local wmoney = money * data.lootRatio // RAND_FACTOR
    local num = tdt // BONUS_TIME
    local wbonus = 0
    local lbonus = 0
    for i = 1, num do
        local rnum = random(RAND_FACTOR)
        if rnum <= data.lootRatio then
            wbonus = wbonus + 1
        else
            lbonus = lbonus + 1
        end
    end
    local m = mail_bonus(wmoney, wbonus, 0, 0, t, info.prof)
    m.content = string.format(explore_win, tinfo.name)
    m.win = true
    skynet.call(offline_mgr, "lua", "add", "mail", info.roleid, m)
    if info.level >= WEEK_TASK_LEVEL then
        skynet.call(task_rank, "lua", "update", 6, info.roleid, tinfo.fight_point)
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
    local agent = skynet.call(role_mgr, "lua", "get", info.roleid)
    if agent then
        skynet.send(agent, "lua", "notify", "update_user", {update={explore={
            status = info.status,
            time = t,
        }}})
    end
    skynet.call(save_explore, "lua", "update", info.roleid, info)
    local lmoney = money * data.loseKeepRatio // RAND_FACTOR
    local exp = data.exp * tdt // 3600
    local sp = data.sp * tdt // 3600
    local tm = mail_bonus(lmoney, lbonus, exp, sp, t, tinfo.prof)
    tm.content = string.format(explore_fail, info.name)
    tm.fail = true
    -- tm.finish = true
    skynet.call(offline_mgr, "lua", "add", "mail", tinfo.roleid, tm)
    tinfo.status = explore_status.FINISH
    tinfo.reason = explore_reason.FAIL
end

local function set(info, del, notice)
    if del then
        role_list[info.roleid] = nil
        if info.guildid then
            local g = guild[info.guildid]
            g[1] = g[1] - 1
            local r = g[2]
            local len = #guild_rank
            while r < len do
                local r1 = r + 1
                local g1 = guild_rank[r1]
                if g[1] < g1[1] then
                    g[2], g1[2] = r1, r
                    guild_rank[r], guild_rank[r1] = g1, g
                    r = r1
                else
                    break
                end
            end
        end
    else
        role_list[info.roleid] = info
        if info.guildid then
            local g = guild[info.guildid]
            if g then
                g[1] = g[1] + 1
                local r = g[2]
                while r > 1 do
                    local r1 = r - 1
                    local g1 = guild_rank[r1]
                    if g[1] > g1[1] then
                        g[2], g1[2] = r1, r
                        guild_rank[r], guild_rank[r1] = g1, g
                        r = r1
                    else
                        break
                    end
                end
            else
                local len = #guild_rank + 1
                g = {1, len, info.guildid}
                guild_rank[len] = g
                guild[info.guildid] = g
            end
        end
    end
    if info.guildid then
        local gid
        local g = guild_rank[1]
        if g[1] >= 6 then
            gid = g[3]
        end
        if gid ~= occupy_guild then
            skynet.call(explore_mgr, "lua", "occupy_guild", data.area, gid)
            if notice then
                local ag = {area=data.area}
                if gid then
                    ag.info = skynet.call(guild_mgr, "lua", "simple_info", gid)
                end
                skynet.call(role_mgr, "lua", "broadcast", "update_user", {update={area_guild={ag}}})
            end
            occupy_guild = gid
        end
    end
end

local function update()
    local now = floor(skynet.time())
    local del_list = {}
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
                        local tinfo = role_list[tid]
                        if tinfo.guildid ~= v.guildid then
                            skynet.call(rankdb, "lua", "zrem", rankname, k)
                            encounter(v, now, tid)
                            skynet.call(rankdb, "lua", "zrem", rankname, tid)
                            encounter(tinfo, now, k)
                            rank_count = rank_count - 2
                            skynet.call(save_explore, "lua", "update", tid, tinfo)
                        end
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
                    del_list[#del_list+1] = tinfo
                else
                    win(now, tinfo, v)
                    del_list[#del_list+1] = v
                end
            end
        elseif v.status == explore_status.IDLE then
            local t = now - v.start_time
            if t >= data.searchSecond then
                local bonus = data.searchSecond // BONUS_TIME
                local exp = data.exp * data.searchSecond // 3600
                local money = data.money * data.searchSecond // 3600
                local sp = data.sp * data.searchSecond // 3600
                local m = mail_bonus(money, bonus, exp, sp, now, v.prof)
                m.content = explore_normal
                m.finish = true
                skynet.call(offline_mgr, "lua", "add", "mail", v.roleid, m)
                v.status = explore_status.FINISH
                v.reason = explore_reason.NORMAL
                del_list[#del_list+1] = v
            end
        end
    end
    for k, v in ipairs(del_list) do
        local roleid = v.roleid
        local tagent = skynet.call(role_mgr, "lua", "get", roleid)
        if tagent then
            skynet.send(tagent, "lua", "notify", "update_user", {update={explore={
                status = v.status, 
                reason = v.reason,
            }}})
        end
        set(v, true, true)
        skynet.call(save_explore, "lua", "update", roleid, false)
        skynet.call(explore_mgr, "lua", "del", roleid)
    end
end

function CMD.open(d, bd, mgr)
    local textdata = sharedata.query("textdata")
    explore_title = func.get_string(198000012)
    explore_win = func.get_string(198000013)
    explore_fail = func.get_string(198000014)
    explore_normal = func.get_string(198000015)
    explore_escape = func.get_string(198000016)
    explore_quit = func.get_string(198000017)
    explore_status = sharedata.query("explore_status")
    explore_reason = sharedata.query("explore_reason")
    data = d
    bonus_data = bd
    explore_mgr = mgr
    rankname = "explore_" .. d.area
    ratio_min = MAX_ENCOUNTER_RATIO // (d.searchTime - ENCOUNTER_MIN)
    save_explore = skynet.queryservice("save_explore")
    role_mgr = skynet.queryservice("role_mgr")
    task_rank = skynet.queryservice("task_rank")
    offline_mgr = skynet.queryservice("offline_mgr")
    guild_mgr = skynet.queryservice("guild_mgr")
    local master = skynet.queryservice("dbmaster")
    rankdb = skynet.call(master, "lua", "get", "rankdb")
    skynet.call(rankdb, "lua", "zremrangebyrank", rankname, 0, -1)
    rank_count = 0
    timer.add_second_routine("update_explore", update)
end

function CMD.enter(roleid)
    local info = role_list[roleid]
    if info then
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
        }
    end
end

function CMD.add(info)
    if info.status == explore_status.NORMAL then
        skynet.call(rankdb, "lua", "zadd", rankname, -info.fight_point, info.roleid)
        rank_count = rank_count + 1
    end
    set(info, false, false)
    skynet.call(explore_mgr, "lua", "add", info.roleid, skynet.self())
end

function CMD.explore(roleid, fight_point, name, prof, level, guildid)
    skynet.call(rankdb, "lua", "zadd", rankname, -fight_point, roleid)
    rank_count = rank_count + 1
    local now = floor(skynet.time())
    local info = {
        roleid = roleid,
        fight_point = fight_point,
        name = name,
        prof = prof,
        level = level,
        guildid = guildid,
        area = data.area,
        start_time = now,
        status = explore_status.NORMAL,
        time = now,
        update_time = now,
    }
    set(info, false, true)
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
            local tdt = t - info.start_time
            local money = data.money * tdt // 3600
            local imoney = money * data.escapeKeepRatio // RAND_FACTOR
            local exp = data.exp * tdt // 3600
            local sp = data.sp * tdt // 3600
            local tmoney = money * data.escapeLootRatio // RAND_FACTOR
            local num = tdt // BONUS_TIME
            local ibonus = 0
            local tbonus = 0
            for i = 1, num do
                local rnum = random(RAND_FACTOR)
                if rnum <= data.escapeKeepRatio then
                    ibonus = ibonus + 1
                else
                    local tnum = random(RAND_FACTOR)
                    if tnum <= data.escapeLootRatio then
                        tbonus = tbonus + 1
                    end
                end
            end
            local m = mail_bonus(imoney, ibonus, exp, sp, t, info.prof)
            m.content = string.format(explore_escape, tinfo.name)
            m.fail = true
            -- m.finish = true
            skynet.call(offline_mgr, "lua", "add", "mail", roleid, m)
            info.status = explore_status.FINISH
            info.reason = explore_reason.ESCAPE
            info.ack = 2
            set(info, true, true)
            skynet.call(save_explore, "lua", "update", roleid, false)
            skynet.call(explore_mgr, "lua", "del", roleid)
            local tm = mail_bonus(tmoney, tbonus, 0, 0, t, tinfo.prof)
            tm.content = string.format(explore_win, info.name)
            tm.win = true
            skynet.call(offline_mgr, "lua", "add", "mail", tinfo.roleid, tm)
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
            return {status=info.status, ack=info.ack, reason=info.reason}
        elseif info.status == explore_status.NORMAL or info.status == explore_status.IDLE then
            if info.status == explore_status.NORMAL then
                skynet.call(rankdb, "lua", "zrem", rankname, roleid)
                rank_count = rank_count - 1
            end
            local t = floor(skynet.time())
            local tdt = (t - info.start_time) * data.quitKeepRatio // RAND_FACTOR
            local money = data.money * tdt // 3600
            local exp = data.exp * tdt // 3600
            local sp = data.sp * tdt // 3600
            local bonus = tdt // BONUS_TIME
            local m = mail_bonus(money, bonus, exp, sp, t, info.prof)
            m.content = explore_quit
            -- m.finish = true
            skynet.call(offline_mgr, "lua", "add", "mail", roleid, m)
            info.status = explore_status.FINISH
            info.reason = explore_reason.QUIT
            set(info, true, true)
            skynet.call(save_explore, "lua", "update", roleid, false)
            skynet.call(explore_mgr, "lua", "del", roleid)
            return {status=info.status, reason=info.reason}
        end
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
