local skynet = require "skynet"
local share = require "share"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local table = table

local data
local base
local error_code
local rank_mgr
local query_process

local rank = {}
local proc = {}

local function query_arena()
    local rank = skynet.call(rank_mgr, "lua", "get", base.RANK_ARENA, data.user.id)
    local r
    if rank <= 3 then
        r = {1, 2, 3, 4}
        table.remove(r, rank + 1)
    else
        r = {}
        for i = 1, 3 do
            rank = (rank * (random(199) + 800)) // 1000
            r[i] = rank
        end
    end
    return {
        rank = rank + 1,
        list = skynet.call(rank_mgr, "lua", "query", base.RANK_ARENA, r),
    }
end

local function query_fight_point()
    local rank = skynet.call(rank_mgr, "lua", "get", base.RANK_FIGHT_POINT, data.user.id)
    local r = {}
    if rank > 0 then
        r[1] = (rank * (random(49) + 950)) // 1000
    end
    return {
        rank = rank + 1,
        list = skynet.call(rank_mgr, "lua", "query", base.RANK_FIGHT_POINT, r),
    }
end

skynet.init(function()
    base = share.base
    error_code = share.error_code
    rank_mgr = skynet.queryservice("rank_mgr")
    query_process = {
        [base.RANK_ARENA] = query_arena,
        [base.RANK_FIGHT_POINT] = query_fight_point,
    }
end)

function rank.init_module()
    return proc
end

function rank.init(userdata)
    data = userdata
end

function rank.exit()
    data = nil
end

---------------------------protocol process----------------------

function proc.query_rank(msg)
    local process = query_process[msg.rank_type]
    if not process then
        error{code = error_code.ERROR_QUERY_RANK_TYPE}
    end
    return "rank_list", process()
end

return rank
