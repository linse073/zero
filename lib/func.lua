local skynet = require "skynet"
local util = require "util"

local func = {}

local day_second = 24 * 60 * 60
local start_routine_time = skynet.getenv("start_routine_time")

function func.game_day(t)
    local st = util.day_time(t)
    return (st - start_routine_time) // day_second
end

return func
