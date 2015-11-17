local share = require "share"

local stagedata = share.stagedata
local data

local stage = {}
local proc = {}

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
        data.stage[k] = {v, assert(stagedata[v.id], string.format("No stage data %d.", v.id))}
        pack[#pack+1] = v
    end
    return "stage", pack
end

function stage.get_proc()
    return proc
end

-----------------------------protocol process--------------------------

return stage
