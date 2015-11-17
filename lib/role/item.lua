local share = require "share"

local itemdata = share.itemdata
local data

local item = {}
local proc = {}

function item.init(userdata)
    data = userdata
end

function item.exit()
    data = nil
end

function item.enter()
    local pack = {}
    data.item = {}
    for k, v in pairs(data.user.item) do
        data.item[k] = {v, assert(itemdata[v.itemid], string.format("No item data %d.", v.itemid))}
        pack[#pack+1] = v
    end
    return "item", pack
end

function item.get_proc()
    return proc
end

----------------------------protocol process------------------------

return item
