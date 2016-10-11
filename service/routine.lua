local skynet = require "skynet"
local func = require "func"
local util = require "util"

local pairs = pairs
local assert = assert
local string = string
local floor = math.floor
local game_day

local routine_list = {}
local once_routine_list = {}
local day_routine_list = {}
local second_routine_list = {}
local running = false
local cur_day
local cur_wday

local function time_routine()
    for k, v in pairs(second_routine_list) do
        skynet.send(v, "lua", "second_routine", k)
    end
    local now = skynet.time()
    for k, v in pairs(routine_list) do
        if now >= v.time then
            v.time = v.time + v.interval
            skynet.send(v.address, "lua", "routine", k)
        end
    end
    for k, v in pairs(once_routine_list) do
        if now >= v.time then
            v.time = v.time + v.interval
            once_routine_list[k] = nil
            skynet.send(v.address, "lua", "once_routine", k)
        end
    end
    local fnow = floor(now)
    local day = game_day(fnow)
    if day ~= cur_day then
        local wday = util.week_time(fnow)
        for k, v in pairs(day_routine_list) do
            skynet.send(v, "lua", "day_routine", k, cur_day, day, cur_wday, wday)
        end
        cur_day = day
        cur_wday = wday
    end
    if running then
        skynet.timeout(100, time_routine)
    end
end

local CMD = {}

function CMD.exit()
    running = false
end

function CMD.add(address, key, interval)
    assert(not routine_list[key], string.format("Already has routine %s.", key))
    routine_list[key] = {
        address = address,
        interval = interval,
        time = skynet.time() + interval,
    }
end

function CMD.del(key)
    routine_list[key] = nil
end

function CMD.add_once(address, key, interval)
    assert(not once_routine_list[key], string.format("Already has once routine %s.", key))
    once_routine_list[key] = {
        address = address,
        interval = interval,
        time = skynet.time() + interval,
    }
end

function CMD.del_once(key)
    once_routine_list[key] = nil
end

function CMD.add_day(address, key)
    assert(not day_routine_list[key], string.format("Already has day routine %s.", key))
    day_routine_list[key] = address
end

function CMD.del_day(key)
    day_routine_list[key] = nil
end

function CMD.add_second(address, key)
    assert(not second_routine_list[key], string.format("Already has second routine %s.", key))
    second_routine_list[key] = address
end

function CMD.del_second(key)
    second_routine_list[key] = nil
end

function CMD.update_day()
    for k, v in pairs(day_routine_list) do
        skynet.send(v, "lua", "day_routine", k, cur_day, cur_day, cur_wday, cur_wday)
    end
end

skynet.start(function()
    game_day = func.game_day
    local now = floor(skynet.time())
    cur_day = game_day(now)
    cur_wday = util.week_time(now)
    running = true
    skynet.timeout(100, time_routine)
    
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
