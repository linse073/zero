local snax = require "snax"
local skynet = require "skynet"

local timer = {}

local routine = snax.queryservice("routine")
local routine_list = {}

function timer.add_routine(key, func, interval)
    routine_list[key] = func
    routine.req.add_routine(skynet.self(), key, interval)
end

function timer.del_routine(key)
    routine.req.del_routine(key)
    routine_list[key] = nil
end

function timer.call_routine(key)
    routine_list[key]()
end

