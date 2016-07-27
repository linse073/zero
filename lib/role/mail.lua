local skynet = require "skynet"
local share = require "share"
local util = require "util"

local item

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

local mail = {}
local proc = {}

skynet.init(function()
    itemdata = share.itemdata
    base = share.base
    error_code = share.error_code
end)

function mail.init_module()
    item = require "role.item"
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

function mail.add(v)
    if not v.id then
        v.id = mail.gen_id()
    end
    if not v.status then
        v.status = base.MAIL_STATUS_UNREAD
    end
    data.mail[v.id] = v
    return v
end

function mail.del(id)
    data.mail[id] = nil
end

function mail.get(id)
    return data.mail[id]
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
        for k, v in ipairs(m.item_info) do
            if v.id then
                local d = assert(itemdata[v.itemid], string.format("No item data %d.", v.itemid))
                item.add_by_info(v, d)
                pitem[#pitem+1] = v
            else
                if v.itemid == base.MONEY_ITEM then
                    role.add_money(p, v.num)
                elseif v.itemid == base.RMB_ITEM then
                    role.add_rmb(p, v.num)
                else
                    local d = assert(itemdata[v.itemid], string.format("No item data %d.", v.itemid))
                    item.add_by_itemid(p, v.num, d)
                end
            end
        end
    end
    return "update_user", {update=p}
end

return mail
