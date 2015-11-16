local taskdata = require "data.task"
local snax = require "sanx"

local data

local task = {}
local proc = {}

local data_mgr = snax.queryservice("data_mgr")
local achi_task, day_task = data_mgr.req.get_task_data()

function task.init(userdata)
    data = userdata
end

function task.exit()
    data = nil
end

function task.enter()
    data.task = {}
    for k, v in pairs(user.task) do
        data.task[k] = {v, assert(taskdata[v.id], string.format("No task data %d.", v.id))}
    end
end

function task.get_proc()
    return proc
end

----------------------------protocol process-------------------------------

return task
