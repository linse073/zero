local snax = require "snax"
local skynet = require "skynet"

local routine_list = {}
local running = false

local function time_routine()
    for k, v in pairs(process) do
        v.time = v.time + 100
        if v.time >= v.interval then
            v.time = v.time - v.interval
            skynet.send(v.address, "lua", "routine", k)
        end
    end
    if running then
        skynet.timeout(100, time_routine)
    end
end

function init()
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
