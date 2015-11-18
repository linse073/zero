local share = require "share"
local timer = require "timer"

local random = math.random
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
    local dt = {}
    local user = data.user
    data.task = dt
    data.day_task = {}
    for k, v in pairs(user.task) do
        local t = task.add(v)
        if t[2].TaskType ~= base.TASK_TYPE_MASTER or v.status ~= base.TASK_STATUS_FINISH then
            pack[#pack+1] = v
        end
    end
    -- repair master task
    if not data.master_task then
        local id = base.BEGIN_TASK_ID
        local t = dt[id]
        while t do
            id = t[2].nextID
            t = dt[id]
        end
        t = task.add_by_id(id, base.TASK_STATUS_ACCEPT)
        pack[#pack+1] = t[1]
    end
    -- repair day task
    local level = user.level
    for k, v in pairs(day_task) do
        if k <= level then
            for k1, v1 in ipairs(v) do
                if not dt[v1.TaskId] then
                    local t = task.add_by_id(v1.TaskId, base.TASK_STATUS_NOT_ACCEPT)
                    pack[#pack+1] = t[1]
                end
            end
        end
    end
    -- repair achievement task
    for k, v in ipairs(achi_task) do
        local d = v
        while d do
            local t = dt[d.TaskId]
            if not t then
                t = task.add_by_id(d.TaskId, base.TASK_STATUS_ACCEPT)
                pack[#pack+1] = t[1]
            end
            if t[1].status == base.TASK_STATUS_FINISH then
                d = taskdata[d.nextID]
            else
                d = nil
            end
        end
    end
    timer.add_day_routine("day_task", task.update_day)
    return "task", pack
end

function task.add(v, d)
    if not d then
        d = assert(taskdata[v.id], string.format("No task data %d.", v.id))
    end
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
    data.task[v.id] = t
    return t
end

function task.add_by_id(id, status)
    local v = {
        id = id,
        status = status,
        count = 0,
    }
    local t = task.add(v)
    data.user.task[id] = v
    return t
end

function task.get_proc()
    return proc
end

function task.update_day()
    local pack = {}
    local td = {}
    for k, v in pairs(data.day_task) do
        local vt = v[1]
        vt.count = 0
        vt.status = base.TASK_STATUS_NOT_ACCEPT
        td[#td+1] = vt
    end
    local count = base.MAX_DAY_TASK
    local l = #td
    if l < count then
        count = l
    end
    for i = 1, count do
        local r = random(l)
        td[l], td[r] = td[r], td[l]
        l = l - 1
    end
    for i = l+1, #td do
        pack[#pack+1] = td[i]
    end
    -- TODO: send to client
end

function task.update_level(ol, nl)
    local pack = {}
    local dt = data.task
    for i = ol+1, nl do
        local lt = day_task[i]
        if lt then
            for k, v in ipairs(lt) do
                local t = dt[v.TaskId]
                if t then
                    skynet.error(string.format("Already has level %d task %d.", i, v.TaskId))
                else
                    t = task.add_by_id(v.TaskId, base.TASK_STATUS_ACCEPT)
                    pack[#pack+1] = t[1]
                end
            end
        end
    end
    return pack
end

----------------------------protocol process-------------------------------

return task
