local skynet = require "skynet"
local share = require "share"
local util = require "util"

local item
local role

local update_user = util.update_user
local error_code
local itemdata
local expdata
local base
local data

local gm = {}
local proc = {}

skynet.init(function()
    error_code = share.error_code
    itemdata = share.itemdata
    expdata = share.expdata
    base = share.base
end)

function gm.init_module()
    item = require "role.item"
    role = require "role.role"
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

return gm
