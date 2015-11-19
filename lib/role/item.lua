local share = require "share"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string

local itemdata = share.itemdata
local base = share.base
local random = math.random
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
    local di = {}
    data.item = di
    data.equip_item = {}
    data.type_item = {}
    for k, v in pairs(data.user.item) do
        item.add(v)
        pack[#pack+1] = v
    end
    return "item", pack
end

function item.add(v, d)
    if not d then
        d = assert(itemdata[v.itemid], string.format("No item data %d.", v.itemid))
    end
    local i = {v, d}
    if v.pos ~= 0 then
        local equip_item = data.equip_item
        if base.is_equip(d.itemType) then
            local pos = d.itemType - base.ITEM_TYPE_HEAD + 1
            if pos ~= v.pos then
                skynet.error(string.format("Equip %d illegal position %d.", v.id, v.pos))
                v.pos = pos
            end
            local ei = equip_item[pos]
            if ei then
                skynet.error(string.format("Position %d already has equip %d.", pos, ei[1].id))
                v.pos = 0
            else
                equip_item[pos] = i
            end
        end
    end
    data.item[v.id] = i
    local type_item = data.type_item
    local t = type_item[v.itemid]
    if not t then
        t = {}
        type_item[v.itemid] = t
    end
    t[v.id] = i
    return i
end

function item.add_by_itemid(itemid, num)
    local pack = {}
    local d = assert(itemdata[itemid], string.format("No item data %d.", itemid))
    local overlay = d.overlay
    if overlay > 1 then
        local t = data.type_item[itemid]
        if t then
            for k, v in pairs(t) do
                local vi = v[1]
                local diff = overlay - vi.num
                if diff > num then
                    diff = num
                end
                vi.num = vi.num + diff
                num = num - diff
                pack[#pack+1] = {
                    id = vi.id,
                    num = vi.num,
                }
                if num == 0 then
                    break
                end
            end
        end
    end
    local category = base.item_category(d.itemType)
    local ui = data.user.item
    while num > 0 do
        local diff = num
        if diff > overlay then
            diff = overlay
        end
        local v = {
            id = data.server.req.gen_item(),
            itemid = itemid,
            owner = 0,
            num = diff,
            pos = 0,
            host = 0,
            upgrade = 0,
            status = base.ITEM_STATUS_NORMAL,
            status_time = 0,
            price = 0,
        }
        if category == base.ITEM_DEFENCE then
            v.rand_prop = {{}, {}}
            item.rand_prop(v, {1, 2, 3, 4}) -- defence, tenacity, hard, offset
        elseif category == base.ITEM_ATTACK then
            v.rand_prop = {{}, {}}
            item.rand_prop(v, {5, 6, 7, 8}) -- break, crit, impale, hit
        end
        item.add(v, d)
        ui[v.id] = v
        pack[#pack+1] = v
    end
    -- TODO: send to client
end

function item.rand_prop(v, r)
    local rand_prop = v.rand_prop
    if r then
        local l = #r
        for i = 1, base.MAX_RAND_PROP do
            local n = random(i, l)
            t[i], t[n] = t[n], t[i]
            rand_prop[i].type = t[i]
        end
    end
    for i = 1, base.MAX_RAND_PROP do
        rand_prop[i].value = 1
        -- TODO: calculate value
    end
end

function item.get_proc()
    return proc
end

----------------------------protocol process------------------------

return item
