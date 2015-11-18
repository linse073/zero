local snax = require "snax"
local skynet = require "skynet"

local date = os.date

local routine_list = {}
local day_routine_list = {}
local running
local role_mgr
local cur_day

local function time_routine()
    for k, v in pairs(process) do
        v.time = v.time + 100
        if v.time >= v.interval then
            v.time = v.time - v.interval
            skynet.send(v.address, "lua", "routine", k)
        end
    end
    local day = date("%j", skynet.time())
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
    role_mgr = snax.queryservice("role_mgr")
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
        time = 0,
    }
end

function response.del_routine(key)
    routine_list[key] = nil
end

function response.add_day_routine(address, key)
    assert(not day_routine_list[key], string.format("Already has day routine %s.", key))
    day_routine_list[key] = address
end

function response.del_day_routine(key)
    day_routine_list[key] = nil
end
