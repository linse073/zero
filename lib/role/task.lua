local skynet = require "skynet"
local share = require "share"

local role = require "role.role"
local item = require "role.item"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local random = math.random

local taskdata
local itemdata
local achi_task
local day_task
local base
local data

local task = {}
local proc = {}

skynet.init(function()
    taskdata = share.taskdata
    itemdata = share.itemdata
    achi_task = share.achi_task
    day_task = share.day_task
    base = share.base
end)

function task.init(userdata)
    data = userdata
end

function task.exit()
    data = nil
end

function task.enter()
    local pack = {}
    local dt = {}
    local user = data.user
    data.task = dt
    data.day_task = {}
    data.accept_task = {}
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
        local d = assert(taskdata[id], string.format("No task data %d.", id))
        t = task.add_by_data(d, base.TASK_STATUS_ACCEPT)
        pack[#pack+1] = t[1]
    end
    -- repair day task
    local level = user.level
    for k, v in pairs(day_task) do
        if k <= level then
            for k1, v1 in ipairs(v) do
                if not dt[v1.TaskId] then
                    local t = task.add_by_data(v1, base.TASK_STATUS_NOT_ACCEPT)
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
                t = task.add_by_data(d, base.TASK_STATUS_ACCEPT)
                pack[#pack+1] = t[1]
            end
            if t[1].status == base.TASK_STATUS_FINISH then
                d = taskdata[d.nextID]
            else
                d = nil
            end
        end
    end
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
    if v.status == base.TASK_STATUS_ACCEPT then
        data.accept_task[v.id] = t
    end
    return t
end

function task.add_by_data(d, status)
    local v = {
        id = d.TaskId,
        status = status,
        count = 0,
    }
    local t = task.add(v, d)
    data.user.task[id] = v
    return t
end

function task.check_add(d, status)
    local t = data.task[d.TaskId]
    if t then
        skynet.error(string.format("Already has task %d.", d.TaskId))
    else
        return task.add_by_data(d, base.TASK_STATUS_ACCEPT)
    end
end

function task.update_day()
    local pack = {}
    local td = {}
    local accept_task = data.accept_task
    for k, v in pairs(data.day_task) do
        local vt = v[1]
        if vt.status == base.TASK_STATUS_ACCEPT then
            accept_task[vt.id] = nil
        end
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
        local r = random(i, l)
        td[i], td[r] = td[r], td[i]
        local v = td[i]
        local vt = v[1]
        vt.status = base.TASK_STATUS_ACCEPT
        accept_task[vt.id] = v
        pack[#pack+1] = vt.id
    end
    return pack
end

function task.update_level(ol, nl)
    local pack = {}
    for i = ol+1, nl do
        local lt = day_task[i]
        if lt then
            for k, v in ipairs(lt) do
                local t = task.check_add(v, base.TASK_STATUS_ACCEPT)
                if t then
                    pack[#pack+1] = t[1]
                end
            end
        end
    end
    return pack
end

function task.update(completeType, condition, count)
    local puser, ptask, pitem
    local ptask = {}
    local user = data.user
    for k, v in pairs(data.accept_task) do
        local vt = v[1]
        local d = v[2]
        if user.level >= d.levelLimit and vt.status == base.TASK_STATUS_ACCEPT and completeType == d.CompleteType
            and (d.condition == 0 or d.condition == condition) then
            vt.count = vt.count + count
            local update = {
                id = vt.id,
                count = vt.count,
            }
            if vt.count >= d.count then
                vt.status = base.TASK_STATUS_DONE
                update.status = vt.status
                if d.TaskType == base.TASK_TYPE_MASTER and d.SubNpc == 0 then
                    local pt = ptask
                    puser, ptask, pitem = task.finish(v)
                    share.merge(ptask, pt)
                    update.status = vt.status
                end
            end
            ptask[#ptask+1] = update
        end
    end
    return puser, ptask, pitem
end

function task.finish(t)
    local vt = t[1]
    vt.status = base.TASK_STATUS_FINISH
    local puser, ptask, pitem = task.award(t)
    local d = t[2]
    if d.TaskType == base.TASK_TYPE_MASTER or d.TaskType == base.TASK_TYPE_ACHIEVEMENT then
        if d.nextID ~= 0 then
            local nd = assert(taskdata[d.nextID], string.format("No task data %d.", d.nextID))
            local nt = task.check_add(nd, base.TASK_STATUS_ACCEPT)
            if nt then
                ptask[#ptask+1] = nt[1]
            end
        end
    end
    return puser, ptask, pitem
end

function task.award(t)
    local user = data.user
    local d = t[2]
    local puser = {}
    local ptask = {}
    if d.EXP > 0 then
        local pu, pt = role.add_exp(d.EXP)
        if pu then
            share.merge_talbe(puser, pu)
        end
        if pt then
            share.merge(ptask, pt)
        end
    end
    if d.Gold > 0 then
        user.money = user.money + d.Gold
        puser.money = user.money
    end
    if d.RMBMoney > 0 then
        user.rmb = user.rmb + d.RMBMoney
        puser.rmb = user.rmb
    end
    local profitem = d.profItem[user.prof]
    local pitem = {}
    if profitem > 0 then
        local idata = assert(itemdata[profitem], string.format("No item data %d.", profitem))
        local pi = item.add_by_itemid(profitem, 1, idata)
        share.merge(pitem, pi)
    end
    for k, v in ipairs(d.Item) do
        if v ~= 0 then
            local n = d.ItemNum[k]
            if n ~= 0 then
                local idata = assert(itemdata[v], string.format("No item data %d.", v))
                local pi = item.add_by_itemid(v, n, idata)
                share.merge(pitem, pi)
            end
        end
    end
    -- TODO: add card
    return puser, ptask, pitem
end

function task.get_proc()
    return proc
end

----------------------------protocol process-------------------------------

function proc.submit_task(msg)
    local t = data.task[msg.id]
    if not t then
        error{code = error_code.TASK_NOT_EXIST}
    end
    local d = t[2]
    local user = data.user
    if user.level < d.levelLimit then
        error{code = error_code.ROLE_LEVEL_LIMIT}
    end
    local vt = t[1]
    local puser, ptask, pitem
    if vt.status == base.TASK_STATUS_ACCEPT then
        if d.CompleteType == base.TASK_COMPLETE_TYPE_TALK then
            puser, ptask, pitem = task.update(base.TASK_COMPLETE_TYPE_TALK, msg.condition, 1)
        end
    elseif vt.status == base.TASK_STATUS_FINISH then
        puser, ptask, pitem = task.finish(t)
    end
    return "user_update", {update={user=puser, task=ptask, item=pitem}}
end

return task
