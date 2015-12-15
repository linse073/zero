local skynet = require "skynet"
local share = require "share"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local random = math.random
local floor = math.floor

local itemdata
local base
local is_equip
local item_category
local data

local item = {}
local proc = {}

skynet.init(function()
    itemdata = share.itemdata
    base = share.base
    is_equip = share.is_equip
    item_category = share.item_category
end)

function item.init(userdata)
    data = userdata
end

function item.exit()
    data = nil
end

function item.enter()
    local pack = {}
    data.item = {}
    data.equip_item = {}
    data.type_item = {}
    data.selling_item = {}
    data.selled_item = {}
    for k, v in pairs(data.user.item) do
        item.add(v)
        pack[#pack+1] = v
    end
    item.post_add()
    -- TODO: calculate player attribute
    return "item", pack
end

function item.post_add()
    for k, v in pairs(data.item) do
        local i = v[1]
        if i.host ~= 0 then
            local host = data.item[i.host]
            if host then
                local t = host[3]
                if not t then
                    t = {}
                    host[3] = t
                end
                t[i.pos] = v
                v[4] = host
            else
                skynet.error(string.format("Item %d host %d not exist.", i.id, i.host))
                i.host = 0
            end
        end
    end
end

function item.add(v, d)
    if not d then
        d = assert(itemdata[v.itemid], string.format("No item data %d.", v.itemid))
    end
    local i = {v, d}
    data.item[v.id] = i
    if v.status == base.ITEM_STATUS_NORMAL then
        if v.pos ~= 0 then
            if is_equip(d.itemType) then
                local pos = d.itemType - base.ITEM_TYPE_HEAD + 1
                if pos ~= v.pos then
                    skynet.error(string.format("Equip %d illegal position %d.", v.id, v.pos))
                    v.pos = pos
                end
                local equip_item = data.equip_item
                local ei = equip_item[pos]
                if ei then
                    skynet.error(string.format("Position %d already has equip %d.", pos, ei[1].id))
                    v.pos = 0
                else
                    equip_item[pos] = i
                end
            else
                skynet.error(string.format("Item %d illegal position %d.", v.id, v.pos))
                v.pos = 0
            end
        end
        local type_item = data.type_item
        local t = type_item[v.itemid]
        if not t then
            t = {}
            type_item[v.itemid] = t
        end
        t[v.id] = i
    elseif v.status == base.ITEM_STATUS_SELLING then
        data.selling_item[v.id] = i
    elseif v.status == base.ITEM_STATUS_SELLED then
        data.selled_item[v.id] = i
    end
    return i
end

function item.add_by_itemid(itemid, num, d)
    local pack = {}
    if not d then
        d = assert(itemdata[itemid], string.format("No item data %d.", itemid))
    end
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
    local category = item_category[d.itemType]
    local ui = data.user.item
    while num > 0 do
        local diff = num
        if diff > overlay then
            diff = overlay
        end
        local v = {
            id = skynet.call(data.server, "lua", "gen_item"),
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
    return pack
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

function item.count(itemid)
    local count = 0
    local items = data.type_item[itemid]
    for k, v in pairs(items) do
        count = count + v[1].num
    end
    return count
end

function item.get_by_pos(pos)
    if pos ~= 0 then
        return data.equip_item[pos]
    end
end

function item.use(i, pos)
    local pack = {}
    local iv = i[1]
    local update = {}
    if iv.status == base.ITEM_STATUS_NORMAL then
        local oi = item.get_by_pos(pos)
        if oi then
            local oiv = oi[1]
            oiv.pos = pos
            item.set(pos, oi)
            pack[#pack+1] = {id=oiv.id, pos=pos}
        else
            item.set(pos)
        end
    elseif iv.status == base.ITEM_STATUS_SELLING then
        iv.status = base.ITEM_STATUS_NORMAL
        iv.status_time = floor(skynet.time())
        local type_item = data.type_item
        local t = type_item[iv.itemid]
        if not t then
            t = {}
            type_item[iv.itemid] = t
        end
        t[iv.id] = i
        data.selling_item[iv.id] = nil
        update.status = iv.status
        update.status_time = iv.status_time
    end
    iv.pos = pos
    update.pos = pos
    item.set(pos, i)
    pack[#pack+1] = update
    return pack
end

function item.set(pos, i)
    if pos ~= 0 then
        data.equip_item[pos] = i
    end
end

function item.del_by_itemid(itemid, num)
    local pack = {}
    local t = assert(data.type_item[itemid], string.format("Item %d not exist.", itemid))
    for k, v in pairs(t) do
        local vi = v[1]
        local diff = num
        if diff > vi.num then
            diff = num
        end
        vi.num = vi.num - diff
        num = num - diff
        local p = {
            id = vi.id,
            num = vi.num,
        }
        if vi.num == 0 then
            item.del(v)
            p.status = vi.status
            p.status_time = vi.status_time
        end
        pack[#pack+1] = p
        if num == 0 then
            break
        end
    end
    assert(num==0, string.format("Item %d num %d insufficient.", itemid, num))
    return pack
end

-- NOTICE: can't delete equip and equip that has stone
function item.del(i)
    local iv = i[1]
    assert(not i[3], string.format("Item %d has stone.", iv.id))
    assert(iv.pos==0, string.format("Can't delete equip %d.", iv.id))
    if iv.status == base.ITEM_STATUS_NORMAL then
        local t = assert(data.type_item[iv.itemid], string.format("Item %d not exist.", iv.itemid))
        t[iv.id] = nil
    elseif iv.status == base.ITEM_STATUS_SELLING then
        data.selling_item[iv.id] = nil
    elseif iv.status == base.ITEM_STATUS_SELLED then
        data.selled_item[iv.id] = nil
    end
    iv.status = base.ITEM_STATUS_DELETE
    iv.status_time = floor(skynet.time())
    data.user.item[iv.id] = nil
    data.item[iv.id] = nil
end

function item.get_proc()
    return proc
end

----------------------------protocol process------------------------

function proc.use_item(msg)
    local i = data.item[msg.id]
    if not i then
        error{code = error_code.ITEM_NOT_EXIST}
    end
    local iv = i[1]
    if iv.pos == msg.pos then
        error{code = error_code.ERROR_ITEM_POSITION}
    end
    if iv.status ~= base.ITEM_STATUS_NORMAL then
        error{code = error_code.ERROR_ITEM_STATUS}
    end
    local idata = i[2]
    local user = data.user
    if user.level < idata.needLv then
        error{code = error_code.ROLE_LEVEL_LIMIT}
    end
    if idata.needJob ~= 0 and user.prof ~= idata.needJob then
        error{code = error_code.ERROR_ROLE_PROFESSION}
    end
    if msg.pos ~= 0 then
        if not share.is_equip(idata.itemType) then
            error{code = error_code.ERROR_ITEM_POSITION}
        end
        local pos = idata.itemType - base.ITEM_TYPE_HEAD + 1
        if msg.pos ~= pos then
            error{code = error_code.ERROR_ITEM_POSITION}
        end
    end
    local pack = {}
    pack.item = item.use(i, msg.pos)
    -- TODO: update mission
    -- TODO: calculate player attribute
    return "user_update", {update=pack}
end

function proc.compound_item(msg)
    local d = itemdata[msg.itemid]
    if not d then
        error{code = error_code.ITEM_ID_NOT_EXIST}
    end
    local compounditem = d.compos
    if compounditem == 0 then
        error{code = error_code.CAN_NOT_COMPOUND_ITEM}
    end
    local compounddata = assert(itemdata[compounditem], string.format("Compound item %d not exist.", compounditem))
    local num = item.count(msg.itemid)
    if msg.num and msg.num < num then
        num = msg.num
    end
    local comnum = floor(num*0.2)
    if comnum == 0 then
        error{code = error_code.ITEM_NUM_LIMIT}
    end
    local pitem = {}
    share.merge(pitem, item.del_by_itemid(msg.itemid, num))
    share.merge(pitem, item.add_by_itemid(compounditem, comnum, compounddata))
    local pack = {}
    pack.item = pitem
    -- TODO: update mission
    return "user_update", {update=pack}
end

return item
