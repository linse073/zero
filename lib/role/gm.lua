local skynet = require "skynet"
local share = require "share"
local util = require "util"

local item
local role
local task
local mail

local floor = math.floor

local update_user = util.update_user
local error_code
local itemdata
local expdata
local taskdata
local base
local data
local offline_mgr

local gm = {}
local proc = {}

skynet.init(function()
    error_code = share.error_code
    itemdata = share.itemdata
    expdata = share.expdata
    taskdata = share.taskdata
    base = share.base
    offline_mgr = skynet.queryservice("offline_mgr")
end)

function gm.init_module()
    item = require "role.item"
    role = require "role.role"
    task = require "role.task"
    mail = require "role.mail"
    return proc
end

function gm.init(userdata)
    data = userdata
end

function gm.exit()
    data = nil
end

--------------------------protocol process-----------------------

function proc.add_item(msg)
    if data.user.gm_level == 0 then
        error{code = error_code.ROLE_NO_PERMIT}
    end
    if not msg.num then
        error{code = error_code.ERROR_ITEM_NUM}
    end
    local d = itemdata[msg.itemid]
    if not d then
        error{code = error_code.ITEM_ID_NOT_EXIST}
    end
    local p = update_user()
    item.add_by_itemid(p, msg.num, d)
    return "update_user", {update=p}
end

function proc.add_exp(msg)
    if data.user.gm_level == 0 then
        error{code = error_code.ROLE_NO_PERMIT}
    end
    local p = update_user()
    role.add_exp(p, msg.exp)
    return "update_user", {update=p}
end

function proc.add_level(msg)
    local user = data.user
    if user.gm_level == 0 then
        error{code = error_code.ROLE_NO_PERMIT}
    end
    local level = user.level + msg.level
    if level > base.MAX_LEVEL then
        level = base.MAX_LEVEL
    end
    local ed = assert(expdata[level-1], string.format("No exp data %d.", level-1))
    local exp = ed.HeroExp - user.exp
    local p = update_user()
    role.add_exp(p, exp)
    return "update_user", {update=p}
end

function proc.add_money(msg)
    if data.user.gm_level == 0 then
        error{code = error_code.ROLE_NO_PERMIT}
    end
    local p = update_user()
    role.add_money(p, msg.money)
    return "update_user", {update=p}
end

function proc.add_rmb(msg)
    if data.user.gm_level == 0 then
        error{code = error_code.ROLE_NO_PERMIT}
    end
    local p = update_user()
    role.add_rmb(p, msg.rmb)
    return "update_user", {update=p}
end

function proc.set_task(msg)
    if data.user.gm_level == 0 then
        error{code = error_code.ROLE_NO_PERMIT}
    end
    local d = taskdata[msg.id]
    if not d then
        error{code = error_code.TASK_NOT_EXIST}
    end
    if d.TaskType ~= base.TASK_TYPE_MASTER then
        error{code = error_code.NOT_MASTER_TASK}
    end
    local p = update_user()
    task.set_task(p, msg.id)
    return "update_user", {update=p}
end

function proc.add_mail(msg)
    if data.user.gm_level == 0 then
        error{code = error_code.ROLE_NO_PERMIT}
    end
    local m = {
        id = mail.gen_id(),
        type = msg.type,
        time = floor(skynet.time()),
        status = base.MAIL_STATUS_UNREAD,
        title = msg.title,
        content = msg.content,
        item_info = msg.item_info,
    }
    mail.add(m)
    local p = update_user()
    p.mail[1] = m
    return "update_user", {update=p}
end

function proc.broadcast_mail(msg)
    if data.user.gm_level == 0 then
        error{code = error_code.ROLE_NO_PERMIT}
    end
    local m = {
        type = msg.type,
        time = floor(skynet.time()),
        status = base.MAIL_STATUS_UNREAD,
        title = msg.title,
        content = msg.content,
        item_info = msg.item_info,
    }
    skynet.call(offline_mgr, "lua", "broadcast_mail", m)
    return "response", ""
end

function proc.test_charge(msg)
    if data.user.gm_level == 0 then
        error{code = error_code.ROLE_NO_PERMIT}
    end
    return role.charge(msg.num)
end

function proc.reset_online_award(msg)
    if data.user.gm_level == 0 then
        error{code = error_code.ROLE_NO_PERMIT}
    end
    local p = update_user()
    local user = data.user
    user.online_award_time = msg.time
    p.user.online_award_time = msg.time
    return "update_user", {update=p}
end

return gm
