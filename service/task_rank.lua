local skynet = require "skynet"
local util = require "util"
local timer = require "timer"
local sharedata = require "sharedata"
local func = require "func"
local queue = require "skynet.queue"

local assert = assert
local ipairs = ipairs
local floor = math.floor
local tonumber = tonumber
local string = string

local rankdb
local task_rank_type
local task_rank_data
local offline_mgr
local title
local content
local cs = queue()

local CMD = {}

local MAIL_TYPE_TASK_RANK = 7

local function award(r, bonus)
    for k, v in ipairs(r) do
        local m = {
            type = MAIL_TYPE_TASK_RANK,
            time = floor(skynet.time()),
            title = title,
            content = string.format(content, k),
        }
        if k < 10 then
            if k == 1 then
                m.item_info = bonus[1][2]
            else
                m.item_info = bonus[1][1]
            end
        elseif k < 100 then
            if k % 10 == 0 then
                m.item_info = bonus[2][2]
            else
                m.item_info = bonus[2][1]
            end
        else
            if k % 100 == 0 then
                m.item_info = bonus[3][2]
            else
                m.item_info = bonus[3][1]
            end
        end
        local id = tonumber(v)
        skynet.call(offline_mgr, "lua", "add", "mail", id, m)
    end
end

local function update_day(od, nd, owd, nwd)
    local r = skynet.call(rankdb, "lua", "zrange", "task", 0, 999)
    skynet.call(rankdb, "lua", "zremrangebyrank", "task", 0, -1)
    skynet.fork(award, r, task_rank_data.bonus)
    task_rank_data = task_rank_type[nwd]
end

function CMD.update(rt, roleid, value)
    if rt == task_rank_data.targetType then
        local score = skynet.call(rankdb, "lua", "zscore", "task", roleid)
        if score then
            score = -tonumber(score) + value
        else
            score = value
        end
        skynet.call(rankdb, "lua", "zadd", "task", -value, roleid)
    end
end

function CMD.get(roleid)
    local cr = skynet.call(rankdb, "lua", "zrank", "task", roleid)
    if cr then
        local score = skynet.call(rankdb, "lua", "zscore", "task", roleid)
        return cr + 1, -tonumber(score)
    end
end

function CMD.shutdown()
    timer.del_day_routine("task_rank")
end

function CMD.day_routine(key, od, nd, owd, nwd)
    timer.call_day_routine(key, od, nd, owd, nwd)
end

-- TODO: call update_day according to server shutdown time
skynet.start(function()
    task_rank_type = sharedata.query("task_rank_type")
    local now = floor(skynet.time())
    local wd = util.week_time(now)
    task_rank_data = task_rank_type[wd]
    offline_mgr = skynet.queryservice("offline_mgr")
    local master = skynet.queryservice("dbmaster")
    rankdb = skynet.call(master, "lua", "get", "rankdb")
    local textdata = sharedata.query("textdata")
    title = func.get_string(198000018)
    content = func.get_string(198000019)
    timer.add_day_routine("task_rank", update_day)

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            cs(f, ...)
        else
            skynet.retpack(cs(f, ...))
        end
	end)
end)
