local share = require "share"
local timer = require "timer"

local taskdata = share.taskdata
local achi_task = share.achi_task
local day_task = share.day_task
local base = share.base
local data

local task = {}
local proc = {}

function task.init(userdata)
    data = userdata
end

function task.exit()
    data = nil
    timer.del_day_routine("day_task")
end

function task.enter()
    local pack = {}
    data.task = {}
    data.day_task = {}
    for k, v in pairs(data.user.task) do
        local t = task.add(v)
        if t[2].TaskType ~= base.TASK_TYPE_MASTER or v.status ~= base.TASK_STATUS_FINISH then
            pack[#pack+1] = v
        end
    end
    if not data.master_task then
        local id = base.BEGIN_TASK_ID
        local t = data.task[id]
        while t do
            id = t[2].nextID
            t = data.task[id]
        end
        local v = {
            id = id,
            status = base.TASK_STATUS_ACCEPT,
            count = 0,
        }
        task.add(v)
        pack[#pack+1] = v
    end
    timer.add_day_routine("day_task", task.update_day)
end

function task.add(v)
    local d = assert(taskdata[v.id], string.format("No task data %d.", v.id))
    local t = {v, d}
    if d.TaskType == base.TASK_TYPE_MASTER then
        if v.status ~= base.TASK_STATUS_FINISH then
            if data.master_task then
                skynet.error(string.format("Already has master task %d.", v.id))
            else
                data.master_task = t
            end
        end
    elseif d.TaskType == base.TASK_TYPE_DAY then
        data.day_task[v.id] = t
    end
    data.task[k] = t
    return t
end

function task.get_proc()
    return proc
end

function task.update_day()
    
end

----------------------------protocol process-------------------------------

return task
