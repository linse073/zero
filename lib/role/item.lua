local itemdata = require "data.item"

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
    data.item = {}
    for k, v in pairs(data.user.item) do
        data.item[k] = {v, assert(itemdata[v.itemid], string.format("No item data %d.", v.itemid))}
    end
end

function item.get_proc()
    return proc
end

----------------------------protocol process------------------------

return item
