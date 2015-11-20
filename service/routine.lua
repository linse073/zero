local snax = require "snax"
local skynet = require "skynet"

local date = os.date
local pairs = pairs
local assert = assert
local string = string

local routine_list = {}
local once_routine_list = {}
local day_routine_list = {}
local running
local cur_day

local function time_routine()
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
    local day = date("%j", now)
    if day ~= cur_day then
        cur_day = day
        for k, v in pairs(day_routine_list) do
            skynet.send(v, "lua", "day_routine", k)
        end
    end
    if running then
        skynet.timeout(100, time_routine)
    end
end

function init()
    cur_day = date("%j", skynet.time())
    running = true
    skynet.timeout(100, time_routine)
end

function exit()
    running = false
end

function response.add_routine(address, key, interval)
    assert(not routine_list[key], string.format("Already has routine %s.", key))
    routine_list[key] = {
        address = address,
        interval = interval,
        time = skynet.time() + interval,
    }
end

function response.del_routine(key)
    routine_list[key] = nil
end

function response.add_once_routine(address, key, interval)
    assert(not once_routine_list[key], string.format("Already has once routine %s.", key))
    once_routine_list[key] = {
        address = address,
        interval = interval,
        time = skynet.time() + interval,
    }
end

function response.del_once_routine(key)
    once_routine_list[key] = nil
end

function response.add_day_routine(address, key)
    assert(not day_routine_list[key], string.format("Already has day routine %s.", key))
    day_routine_list[key] = address
end

function response.del_day_routine(key)
    day_routine_list[key] = nil
end
