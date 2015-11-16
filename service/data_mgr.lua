local taskdata = require "data.task"
local base = require "base"

local achi_task = {}
local day_task = {}

function init()
    for k, v in pairs(taskdata) do
        if v.TaskType == base.TASK_TYPE_DAY then
            local t = day_task[v.levelLimit]
            if t then
                t[#t+1] = v
            else
                day_task[v.levelLimit] = {v}
            end
        elseif v.TaskType == base.TASK_TYPE_ACHIEVEMENT then
            if v.levelLimit == 0 then
                achi_task[#achi_task+1] = v
            end
        end
    end
end

function exit()
    
end

function response.get_task_data()
    return achi_task, day_task
end
