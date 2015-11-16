local snax = require "snax"
local skynet = require "skynet"

local timer = {}

local routine = snax.queryservice("routine")
local routine_list = {}
local day_routine_list = {}

local function gen_key(key)
    return string.format("%d_%s", skynet.self(), key)
end

function timer.add_routine(key, func, interval)
    key = gen_key(key)
    assert(not routine_list[key], string.format(
    routine_list[key] = func
    routine.req.add_routine(skynet.self(), key, interval)
end

function timer.del_routine(key)
    key = gen_key(key)
    routine.req.del_routine(key)
    routine_list[key] = nil
end

function timer.call_routine(key)
    key = gen_key(key)
    routine_list[key]()
end

function timer.add_day_routine(key, func)
    key = gen_key(key)
end
