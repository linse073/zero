local skynet = require "skynet"
local share = require "share"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string

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

function stage.add_by_id(id)
    local v = {
        id = id,
        star = 0,
        day_count = 0,
        total_count = 0,
        best_time = 0,
        best_hit = 0,
    }
    local s = stage.add(v)
    data.user.stage[id] = v
    return s
end

function stage.get_proc()
    return proc
end

-----------------------------protocol process--------------------------

return stage
