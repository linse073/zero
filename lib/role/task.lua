local taskdata = require "data.task"
local base = require "base"

local data

local task = {}
local proc = {}

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
