local skynet = require "skynet"
local share = require "share"
local util = require "util"
local notify = require "notify"

local role
local item
local task

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string

local update_user = util.update_user
local itemdata
local data
local base
local error_code
local rank_mgr
local task_rank

local mail = {}
local proc = {}

skynet.init(function()
    itemdata = share.itemdata
    base = share.base
    error_code = share.error_code
    rank_mgr = skynet.queryservice("rank_mgr")
    task_rank = skynet.queryservice("task_rank")
end)

function mail.init_module()
    item = require "role.item"
    role = require "role.role"
    task = require "role.task"
    return proc
end

function mail.init(userdata)
    data = userdata
end

function mail.exit()
    data = nil
end

function mail.enter()
    data.mail = data.user.mail
end

function mail.pack_all()
    local pack = {}
    for k, v in pairs(data.user.mail) do
        pack[#pack+1] = v
    end
    return "mail", pack
end

function mail.gen_id()
    return skynet.call(data.server, "lua", "gen_mail")
end

function mail.add(v, p)
    if not v.id then
        v.id = mail.gen_id()
    end
    if not v.status then
        v.status = base.MAIL_STATUS_UNREAD
    end
    if v.win then
        task.update(p, base.TASK_COMPLETE_EXPLORE_ENCOUNTER, 1, 1)
        v.win = nil
    end
    if v.fail then
        task.update(p, base.TASK_COMPLETE_EXPLORE_ENCOUNTER, 2, 1)
        v.fail = nil
        data.explore = nil
    end
    if v.finish then
        task.update(p, base.TASK_COMPLETE_EXPLORE, 0, 1)
        v.finish = nil
        data.explore = nil
    end
    data.mail[v.id] = v
    local pm = p.mail
    pm[#pm+1] = v
    return v
end

function mail.del(id)
    data.mail[id] = nil
end

function mail.get(id)
    return data.mail[id]
end

function mail.notify(info)
    local p = update_user()
    mail.add(info, p)
    notify.add("update_user", {update=p})
end

---------------------------protocol process----------------------

function proc.read_mail(msg)
    local m = data.mail[msg.id]
    if not m then
        error{code = error_code.MAIL_NOT_EXIST}
    end
    if m.status ~= base.MAIL_STATUS_UNREAD then
        error{code = error_code.ERROR_MAIL_STATUS}
    end
    m.status = base.MAIL_STATUS_READ
    local p = update_user()
    p.mail[1] = {id=m.id, status=m.status}
    return "update_user", {update=p}
end

function proc.del_mail(msg)
    local m = data.mail[msg.id]
    if not m then
        error{code = error_code.MAIL_NOT_EXIST}
    end
    m.status = base.MAIL_STATUS_DELETE
    mail.del(m.id)
    local p = update_user()
    p.mail[1] = {id=m.id, status=m.status}
    local pitem = p.item
    if m.item_info then
        local money = 0
        for k, v in ipairs(m.item_info) do
            if v.id then
                local d = assert(itemdata[v.itemid], string.format("No item data %d.", v.itemid))
                item.add_by_info(v, d)
                pitem[#pitem+1] = v
            else
                if v.itemid == base.MONEY_ITEM then
                    role.add_money(p, v.num)
                    money = money + v.num
                elseif v.itemid == base.RMB_ITEM then
                    role.add_rmb(p, v.num)
                elseif v.itemid == base.EXP_ITEM then
                    role.add_exp(p, v.num)
                else
                    local d = assert(itemdata[v.itemid], string.format("No item data %d.", v.itemid))
                    item.add_by_itemid(p, v.num, d)
                end
            end
        end
        if money > 0 then
            if m.type == base.MAIL_TYPE_EXPLORE then
                local user = data.user
                user.explore_award = user.explore_award + money
                local se = skynet.call(rank_mgr, "lua", "get", base.RANK_SLAVE_EXPLORE)
                skynet.call(se, "lua", "update", user.id, user.explore_award)
                task.update(p, base.TASK_COMPLETE_EXPLORE_MONEY, 0, 0, user.explore_award)
                if user.level >= base.WEEK_TASK_LEVEL then
                    skynet.call(task_rank, "lua", "update", 2, user.id, money)
                end
            elseif m.type == base.MAIL_TYPE_TRADE then
                task.update(p, base.TASK_COMPLETE_TRADE, 2, 0, money)
            end
        end
    end
    return "update_user", {update=p}
end

return mail
