local skynet = require "skynet"
local share = require "share"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local random = math.random

local stagedata
local data

local stage = {}
local proc = {}

skynet.init(function()
    stagedata = share.stagedata
end)

function stage.init(userdata)
    data = userdata
end

function stage.exit()
    data = nil
end

function stage.enter()
    local pack = {}
    data.stage = {}
    for k, v in pairs(data.user.stage) do
        stage.add(v)
        pack[#pack+1] = v
    end
    return "stage", pack
end

function stage.add(v, d)
    if not d then
        d = {v, assert(stagedata[v.id], string.format("No stage data %d.", v.id))}
    end
    local s = {v, d}
    data.stage[v.id] = s
    return s
end

function stage.add_by_data(d)
    local v = {
        id = d.id,
        star = 0,
        day_count = 0,
        total_count = 0,
        best_time = 0,
        best_hit = 0,
    }
    local s = stage.add(v, d)
    data.user.stage[d.id] = v
    return s
end

function stage.get_proc()
    return proc
end

-----------------------------protocol process--------------------------

function proc.begin_stage(msg)
    local d = stagedata[msg.id]
    if not d then
        error{code = error_code.STAGE_ID_NOT_EXIST}
    end
    local user = data.user
    if user.level < d.limitLevel then
        error{code = error_code.ROLE_LEVEL_LIMIT}
    end
    if d.PreId ~= 0 then
        local ps = data.stage[d.PreId]
        if not ps then
            error{code = error_code.PRE_STAGE_NOT_COMPLETE}
        end
    end
    local pstage
    local s = data.stage[msg.id]
    if not s then
        s = stage.add_by_data(d)
        pstage = s[1]
    end
    local seed = random(base.RAND_FACTOR)
    s[3] = seed
end

function proc.end_stage(msg)
    
end

return stage
