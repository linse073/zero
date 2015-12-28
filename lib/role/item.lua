local skynet = require "skynet"
local share = require "share"
local util = require "util"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local random = math.random
local floor = math.floor
local pow = math.pow

local merge = util.merge
local itemdata
local expdata
local intensifydata
local base
local cs
local is_equip
local is_material
local item_category
local data

local item = {}
local proc = {}

skynet.init(function()
    itemdata = share.itemdata
    expdata = share.expdata
    intensifydata = share.intensifydata
    base = share.base
    cs = share.cs
    is_equip = share.is_equip
    is_material = share.is_material
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
    item.after_add()
    -- TODO: calculate player attribute
    return "item", pack
end

function item.add_to_type(i)
    local v = i[1]
    local type_item = data.type_item
    local t = type_item[v.itemid]
    if not t then
        t = {}
        type_item[v.itemid] = t
    end
    t[v.id] = i
end

function item.del_from_type(i)
    local v = i[1]
    local t = assert(data.type_item[v.itemid], string.format("Item %d not exist.", v.itemid))
    t[v.id] = nil
end

function item.gen_id()
    return skynet.call(data.server, "lua", "gen_item")
end

function item.after_add()
    for k, v in pairs(data.item) do
        local i = v[1]
        if i.host ~= 0 then
            local host = data.item[i.host]
            if host then
                local t = host[3]
                if not t then
                    t = {num = 0}
                    host[3] = t
                end
                t[i.pos] = v
                t.num = t.num + 1
                v[4] = host
            else
                skynet.error(string.format("Item %d host %d not exist.", i.id, i.host))
                i.host = 0
                item.add_to_type(i)
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
            elseif v.host == 0 then
                skynet.error(string.format("Item %d illegal position %d.", v.id, v.pos))
                v.pos = 0
            end
        end
        if v.host == 0 then
            item.add_to_type(i)
        end
    elseif v.status == base.ITEM_STATUS_SELLING then
        data.selling_item[v.id] = i
    elseif v.status == base.ITEM_STATUS_SELLED then
        data.selled_item[v.id] = i
    end
    return i
end

function item.add_by_itemid(itemid, num, d)
    local pack = {}
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
            id = cs(item.gen_id),
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
            item.rand_prop(v, d, {1, 2, 3, 4}) -- defence, tenacity, hard, offset
        elseif category == base.ITEM_ATTACK then
            v.rand_prop = {{}, {}}
            item.rand_prop(v, d, {5, 6, 7, 8}) -- break, crit, impale, hit
        end
        item.add(v, d)
        ui[v.id] = v
        num = num - diff
        pack[#pack+1] = v
    end
    return pack
end

function item.rand_prop(v, d, r)
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
        local value = pow(1.2, d.quality - 1) * (d.needLv * 0.5 + 1)
        rand_prop[i].value = floor(value * base.FLOAT_FACTOR)
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
        item.add_to_type(i)
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

-- NOTICE: can't delete equip, gem and item that has stone
function item.del(i)
    local iv = i[1]
    assert(not i[3], string.format("Item %d has stone.", iv.id))
    assert(not i[4], string.format("Can't delete stone %d.", iv.id))
    assert(iv.pos==0, string.format("Can't delete equip %d.", iv.id))
    if iv.status == base.ITEM_STATUS_NORMAL then
        item.del_from_type(i)
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

function item.change(i, itemid, d)
    local iv = i[1]
    item.del_from_type(i)
    iv.itemid = itemid
    i[2] = d
    item.add_to_type(i)
    item.rand_prop(iv, d)
    return {id=iv.id, itemid=itemid, rand_prop=iv.rand_prop}
end

function item.split(itemid)
    local t = data.type_item[itemid]
    if t then
        local i, minnum
        for k, v in pairs(t) do
            local num = v[1].num
            if not i or num < minnum then
                i = v
                minnum = num
                if num == 1 then
                    break
                end
            end
        end
        if i then
            if minnum == 1 then
                return i
            else
                local iv = i[1]
                assert(minnum > 1, string.format("Item %d num %d error.", iv.id, minnum))
                iv.num = iv.num - 1
                local p = {
                    id = iv.id,
                    num = iv.num,
                }
                local v = {
                    id = cs(item.gen_id),
                    itemid = itemid,
                    owner = 0,
                    num = 1,
                    pos = 0,
                    host = 0,
                    upgrade = 0,
                    status = base.ITEM_STATUS_NORMAL,
                    status_time = 0,
                    price = 0,
                }
                local si = item.add(v, i[2])
                data.user.item[v.id] = v
                return si, p
            end
        end
    end
end

function item.inlay(i, si, j)
    local iv = i[1]
    local st = assert(i[3], string.format("item %d slot not exist.", iv.id))
    local siv = si[1]
    siv.host = iv.id
    siv.pos = j
    si[4] = i
    item.del_from_type(si)
    st[j] = si
    st.num = st.num + 1
    return {id=siv.id, host=siv.host, pos=siv.pos}
end

function item.uninlay(i, si, j)
    local iv = i[1]
    local st = assert(i[3], string.format("item %d slot not exist.", iv.id))
    local siv = si[1]
    siv.host = 0
    siv.pos = 0
    si[4] = nil
    item.add_to_type(si)
    st[j] = nil
    st.num = st.num - 1
    return {id=siv.id, host=siv.host, pos=siv.pos}
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
        if not is_equip(idata.itemType) then
            error{code = error_code.ERROR_ITEM_POSITION}
        end
        local pos = idata.itemType - base.ITEM_TYPE_HEAD + 1
        if msg.pos ~= pos then
            error{code = error_code.ERROR_ITEM_POSITION}
        end
    end
    local pitem = item.use(i, msg.pos)
    -- TODO: update mission
    -- TODO: calculate player attribute
    return "user_update", {update={item=pitem}}
end

function proc.compound_item(msg)
    local d = itemdata[msg.itemid]
    if not d then
        error{code = error_code.ITEM_ID_NOT_EXIST}
    end
    if not is_material(d.itemType) then
        error{code = error_code.ERROR_ITEM_TYPE}
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
    local pitem = item.del_by_itemid(msg.itemid, comnum*5)
    merge(pitem, item.add_by_itemid(compounditem, comnum, compounddata))
    -- TODO: update mission
    return "user_update", {update={item=pitem}}
end

function proc.upgrade_item(msg)
    local i = data.item[msg.id]
    if not i then
        error{code = error_code.ITEM_NOT_EXIST}
    end
    local d = i[2]
    if not is_equip(d.itemType) then
        error{code = error_code.ERROR_ITEM_TYPE}
    end
    local iv = i[1]
    if iv.status ~= base.ITEM_STATUS_NORMAL then
        error{code = error_code.ERROR_ITEM_STATUS}
    end
    local mat = d.compos
    local matdata = assert(itemdata[mat], string.format("Upgrade item %d material %d not exist.", iv.itemid, mat))
    local numdata = assert(expdata[d.needLv], string.format("Upgrade item %d exp data not exist.", iv.itemid))
    local num = numdata.UpgradeMatNum
    local count = item.count(mat)
    if count < num then
        error{code = error_code.ITEM_NUM_LIMIT}
    end
    local upgradeitemid = iv.itemid + 1
    local udata = itemdata[upgradeitemid]
    if not udata then
        error{code = error_code.CAN_NOT_UPGRADE_ITEM}
    end
    local pitem = item.del_by_itemid(mat, num)
    pitem[#pitem+1] = item.change(i, upgradeitemid, udata)
    -- TODO: update mission
    -- TODO: calculate player attribute possibly
    return "user_update", {update={item=pitem}}
end

function proc.improve_item(msg)
    local i = data.item[msg.id]
    if not i then
        error{code = error_code.ITEM_NOT_EXIST}
    end
    local d = i[2]
    if not is_equip(d.itemType) then
        error{code = error_code.ERROR_ITEM_TYPE}
    end
    local iv = i[1]
    if iv.status ~= base.ITEM_STATUS_NORMAL then
        error{code = error_code.ERROR_ITEM_STATUS}
    end
    local mat = d.compos
    local matdata = assert(itemdata[mat], string.format("Improve item %d material %d not exist.", iv.itemid, mat))
    local numdata = assert(expdata[d.needLv], string.format("Improve item %d exp data not exist.", iv.itemid))
    local num = numdata.ImproveMatNum
    local count = item.count(mat)
    if count < num then
        error{code = error_code.ITEM_NUM_LIMIT}
    end
    local improveitemid = iv.itemid + 5000
    local idata = itemdata[improveitemid]
    if not idata then
        error{code = error_code.CAN_NOT_IMPROVE_ITEM}
    end
    local pitem = item.del_by_itemid(mat, num)
    pitem[#pitem+1] = item.change(i, improveitemid, idata)
    -- TODO: update mission
    -- TODO: calculate player attribute possibly
    return "user_update", {update={item=pitem}}
end

function proc.decompose_item(msg)
    local i = data.item[msg.id]
    if not i then
        error{code = error_code.ITEM_NOT_EXIST}
    end
    local d = i[2]
    if not is_equip(d.itemType) then
        error{code = error_code.ERROR_ITEM_TYPE}
    end
    local iv = i[1]
    if iv.status ~= base.ITEM_STATUS_NORMAL then
        error{code = error_code.ERROR_ITEM_STATUS}
    end
    if iv.pos ~= 0 then
        error{code = error_code.ITEM_IN_USE}
    end
    local st = i[3]
    if st and st.num > 0 then
        error{code = error_code.ITEM_HAS_STONE}
    end
    local mat = d.compos
    local matdata = assert(itemdata[mat], string.format("Decompose item %d material %d not exist.", iv.itemid, mat))
    local numdata = assert(expdata[d.needLv], string.format("Decompose item %d exp data not exist.", iv.itemid))
    item.del(i)
    local num = numdata.DecomposeMatNum
    local pitem = item.add_by_itemid(mat, num, matdata)
    pitem[#pitem+1] = {
        id = iv.id,
        status = iv.status,
        status_time = iv.status_time,
    }
    -- TODO: update mission
    return "user_update", {update={item=pitem}}
end

function proc.intensify_item(msg)
    local i = data.item[msg.id]
    if not i then
        error{code = error_code.ITEM_NOT_EXIST}
    end
    local d = i[2]
    if not is_equip(d.itemType) then
        error{code = error_code.ERROR_ITEM_TYPE}
    end
    local iv = i[1]
    if iv.status ~= base.ITEM_STATUS_NORMAL then
        error{code = error_code.ERROR_ITEM_STATUS}
    end
    if iv.intensify >= base.MAX_INTENSIFY then
        error{code = error_code.MAX_INTENSIFY}
    end
    local intensify = iv.intensify + 1
    local idata = assert(intensifydata[intensify], string.format("No intensify data %d.", intensify))
    if d.needLv < idata.levelLimit then
        error{code = error_code.ITEM_LEVEL_LIMIT}
    end
    if d.quality < idata.qualityLimit then
        error{code = error_code.ITEM_QUALITY_LIMIT}
    end
    local count = item.count(base.INTENSIFY_ITEM)
    if count == 0 then
        error{code = error_code.ITEM_NUM_LIMIT}
    end
    local pitem = item.del_by_itemid(base.INTENSIFY_ITEM, 1)
    local r = random(base.RAND_FACTOR)
    if r < idata.rate then
        iv.intensify = iv.intensify + 1
        pitem[#pitem+1] = {
            id = iv.id,
            intensify = iv.intensify,
        }
        -- TODO: update mission
        -- TODO: calculate player attribute possibly
    else
        local punishitem = iv.itemid
        local levelRand = random(base.RAND_FACTOR)
        if levelRand < idata.levelRate then
            punishitem = punishitem - idata.punishLevel * 1000
        end
        local qualityRand = random(base.RAND_FACTOR)
        if qualityRand < idata.qualityRate then
            punishitem = punishitem - idata.punishQuality
        end
        local update
        if punishitem ~= iv.itemid then
            local pdata = assert(itemdata[punishitem], string.format("No item data %d.", punishitem))
            local oldSlot = floor(d.needLv*0.1)
            local newSlot = floor(pdata.needLv*0.1)
            if newSlot < oldSlot then
                local st = i[3]
                if st and st.num > 0 then
                    for j = newSlot, oldSlot do
                        local si = st[j]
                        if si then
                            pitem[#pitem+1] = item.uninlay(i, si, j)
                        end
                    end
                end
            end
            update = item.change(i, punishitem, pdata)
        end
        iv.intensify = iv.intensify - idata.punishIntensify
        assert(iv.intensify>=0, string.format("Punish intensify data %d error.", intensify))
        if update then
            update.intensify = iv.intensify
        else
            update = {
                id = iv.id,
                intensify = iv.intensify,
            }
        end
        pitem[#pitem+1] = update
        -- TODO: calculate player attribute possibly
    end
    return "user_update", {update={item=pitem}}
end

function proc.inlay_item(msg)
    local i = data.item[msg.id]
    if not i then
        error{code = error_code.ITEM_NOT_EXIST}
    end
    local d = i[2]
    if not is_equip(d.itemType) then
        error{code = error_code.ERROR_ITEM_TYPE}
    end
    local iv = i[1]
    if iv.status ~= base.ITEM_STATUS_NORMAL then
        error{code = error_code.ERROR_ITEM_STATUS}
    end
    local st = i[3]
    if not st then
        st = {num = 0}
        i[3] = st
    end
    local pitem = {}
    local slot = floor(d.needLv*0.1)
    for j = 1, slot do
        if not st[j] then
            local stoneitem = 3000000000+(d.itemType-base.ITEM_TYPE_HEAD+base.ITEM_TYPE_BLUE_STONE)*10+j-1
            local si, p = item.split(stoneitem)
            if si then
                if p then
                    pitem[#pitem+1] = p
                end
                pitem[#pitem+1] = item.inlay(i, si, j)
            end
        end
    end
    -- TODO: update mission
    -- TODO: calculate player attribute possibly
    return "user_update", {update={item=pitem}}
end

function proc.uninlay_item(msg)
    local i = data.item[msg.id]
    if not i then
        error{code = error_code.ITEM_NOT_EXIST}
    end
    local d = i[2]
    if not is_equip(d.itemType) then
        error{code = error_code.ERROR_ITEM_TYPE}
    end
    local iv = i[1]
    if iv.status ~= base.ITEM_STATUS_NORMAL then
        error{code = error_code.ERROR_ITEM_STATUS}
    end
    local st = i[3]
    if st and st.num > 0 then
        local pitem = {}
        local slot = floor(d.needLv*0.1)
        for j = 1, slot do
            local si = st[j]
            if si then
                pitem[#pitem+1] = item.uninlay(i, si, j)
            end
        end
        assert(st.num==0, string.format("Uninlay item %d error num %d.", iv.id, st.num))
        -- TODO: update mission
        -- TODO: calculate player attribute possibly
        return "user_update", {update={item=pitem}}
    else
        return "user_update", {}
    end
end

return item
