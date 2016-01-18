local share = require "share"
local util = require "util"

local item

local update_user = util.update_user
local error_code
local itemdata
local data

local gm = {}
local proc = {}

skynet.init(function()
    error_code = share.error_code
    itemdata = share.itemdata
end)

function gm.init_module()
    item = require "role.item"
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

return gm
