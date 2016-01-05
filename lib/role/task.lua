local skynet = require "skynet"
local share = require "share"
local util = require "util"

local role = require "role.role"
local item = require "role.item"
local card = require "role.card"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local random = math.random

local update_user = util.update_user
local taskdata
local itemdata
local carddata
local achi_task
local day_task
local base
local data

local task = {}
local proc = {}

skynet.init(function()
    taskdata = share.taskdata
    itemdata = share.itemdata
    carddata = share.carddata
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
        if not dt[v.TaskId] then
            local t = task.add_by_data(v, base.TASK_STATUS_ACCEPT)
            pack[#pack+1] = t[1]
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

function task.check_add(p, d, status)
    local t = data.task[d.TaskId]
    if t then
        skynet.error(string.format("Already has task %d.", d.TaskId))
    else
        t = task.add_by_data(d, base.TASK_STATUS_ACCEPT)
        local ptask = p.task
        ptask[#ptask+1] = t[1]
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

function task.update_level(p, ol, nl)
    for i = ol+1, nl do
        local lt = day_task[i]
        if lt then
            for k, v in ipairs(lt) do
                task.check_add(p, v, base.TASK_STATUS_ACCEPT)
            end
        end
    end
end

function task.update(p, completeType, condition, count, setCount)
    local ptask = p.task
    local user = data.user
    for k, v in pairs(data.accept_task) do
        local vt = v[1]
        local d = v[2]
        if user.level >= d.levelLimit and vt.status == base.TASK_STATUS_ACCEPT and completeType == d.CompleteType
            and (d.condition == 0 or d.condition == condition) then
            if setCount then
                vt.count = setCount
            else
                vt.count = vt.count + count
            end
            local update = {
                id = vt.id,
                count = vt.count,
            }
            if vt.count >= d.count then
                vt.status = base.TASK_STATUS_DONE
                if d.TaskType == base.TASK_TYPE_MASTER and d.SubNpc == 0 then
                    task.finish(p, v)
                end
                update.status = vt.status
            end
            ptask[#ptask+1] = update
        end
    end
end

function task.finish(p, t)
    local vt = t[1]
    vt.status = base.TASK_STATUS_FINISH
    task.award(p, t)
    local d = t[2]
    if d.TaskType == base.TASK_TYPE_MASTER and d.nextID > 0 then
        local nd = assert(taskdata[d.nextID], string.format("No task data %d.", d.nextID))
        task.check_add(p, nd, base.TASK_STATUS_ACCEPT)
    end
end

function task.award(p, t)
    local user = data.user
    local d = t[2]
    if d.EXP > 0 then
        role.add_exp(p, d.EXP)
    end
    if d.Gold > 0 then
        role.add_money(p, d.Gold)
    end
    if d.RMBMoney > 0 then
        role.add_rmb(p, d.RMBMoney)
    end
    local profitem = d.profItem[user.prof]
    if profitem > 0 then
        local idata = assert(itemdata[profitem], string.format("No item data %d.", profitem))
        item.add_by_itemid(p, profitem, 1, idata)
    end
    for k, v in ipairs(d.Item) do
        if v > 0 then
            local n = d.ItemNum[k]
            if n > 0 then
                local idata = assert(itemdata[v], string.format("No item data %d.", v))
                item.add_by_itemid(p, v, n, idata)
            else
                skynet.error("Task data %d item num error.", d.TaskId)
            end
        end
    end
    local profcard = d.CardId[user.prof]
    if profcard > 0 then
        local cdata = assert(carddata[profcard], string.format("No card data %d.", profcard))
        card.add_by_cardid(p, profcard, cdata)
    end
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
    local p = user_update()
    local vt = t[1]
    if vt.status == base.TASK_STATUS_ACCEPT then
        if d.CompleteType == base.TASK_COMPLETE_TYPE_TALK then
            task.update(p, base.TASK_COMPLETE_TALK, msg.condition, 1)
        end
    elseif vt.status == base.TASK_STATUS_DONE then
        task.finish(p, t)
    end
    return "user_update", {update=p}
end

return task
