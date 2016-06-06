local skynet = require "skynet"
local share = require "share"
local util = require "util"
local new_rand = require "random"
local func = require "func"

local task
local role
local stage

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local random = math.random
local floor = math.floor

local update_user = util.update_user
local itemdata
local expdata
local intensifydata
local base
local error_code
-- local cs
local is_equip
local is_material
local is_chest
local item_category
local data

local item = {}
local proc = {}

skynet.init(function()
    itemdata = share.itemdata
    expdata = share.expdata
    intensifydata = share.intensifydata
    base = share.base
    error_code = share.error_code
    -- cs = share.cs
    is_equip = func.is_equip
    is_material = func.is_material
    is_chest = func.is_chest
    item_category = share.item_category
end)

function item.init_module()
    task = require "role.task"
    role = require "role.role"
    stage = require "role.stage"
    return proc
end

function item.init(userdata)
    data = userdata
end

function item.exit()
    data = nil
end

function item.enter()
    data.item = {}
    data.equip_item = {}
    data.type_item = {}
    data.selling_item = {}
    data.selled_item = {}
    for k, v in pairs(data.user.item) do
        item.add(v)
    end
    item.after_add()
end

function item.pack_all()
    local pack = {}
    for k, v in pairs(data.user.item) do
        pack[#pack+1] = v
    end
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
        if i.host > 0 then
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
    if v.intensify > 0 then
        i[5] = assert(intensifydata[v.intensify], string.format("No intensify data %d.", v.intensify))
    end
    data.item[v.id] = i
    if v.status == base.ITEM_STATUS_NORMAL then
        if v.pos > 0 then
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

function item.add_by_itemid(p, num, d)
    if d.itemType == base.ITEM_TYPE_AUTO_CHEST then
        local bonus = {}
        for k, v in ipairs(d.chest) do
            bonus[k] = {rand_num=num, data=v}
        end
        stage.get_bonus(bonus, p)
    else
        local itemid = d.id
        assert(num>0, string.format("Add item %d num error.", itemid))
        local pack = p.item
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
                -- id = cs(item.gen_id),
                id = item.gen_id(),
                itemid = itemid,
                owner = 0,
                num = diff,
                pos = 0,
                host = 0,
                intensify = 0,
                status = base.ITEM_STATUS_NORMAL,
                status_time = 0,
                price = 0,
            }
            if category == base.ITEM_DEFENCE then
                v.rand_prop = {{}, {}}
                item.rand_prop(v, d, {1, 2, 3, 4}) -- defence, tenacity, block, dodge
            elseif category == base.ITEM_ATTACK then
                v.rand_prop = {{}, {}}
                item.rand_prop(v, d, {5, 6, 7, 8}) -- sunder, crit, impale, hit
            end
            item.add(v, d)
            ui[v.id] = v
            num = num - diff
            pack[#pack+1] = v
        end
    end
end

function item.rand_prop(v, d, r)
    local rand_prop = v.rand_prop
    if r then
        local l = #r
        for i = 1, base.MAX_RAND_PROP do
            local n = random(i, l)
            r[i], r[n] = r[n], r[i]
            rand_prop[i].type = r[i]
        end
    end
    for i = 1, base.MAX_RAND_PROP do
        local value = (1.2 ^ (d.quality - 1)) * (d.needLv * 0.5 + 1) * 2
        rand_prop[i].value = floor(value * base.FLOAT_FACTOR)
    end
end

function item.count(itemid)
    local count = 0
    local items = data.type_item[itemid]
    if items then
        for k, v in pairs(items) do
            count = count + v[1].num
        end
    end
    return count
end

function item.get_by_pos(pos)
    if pos > 0 then
        return data.equip_item[pos]
    end
end

function item.use(p, i, pos)
    local pack = p.item
    local iv = i[1]
    local update = {id=iv.id}
    if iv.status == base.ITEM_STATUS_NORMAL then
        local opos = iv.pos
        local oi = item.get_by_pos(pos)
        if oi then
            local oiv = oi[1]
            oiv.pos = opos
            item.set(opos, oi)
            pack[#pack+1] = {id=oiv.id, pos=opos}
        else
            item.set(opos)
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
end

function item.set(pos, i)
    if pos > 0 then
        data.equip_item[pos] = i
    end
end

function item.del_by_itemid(p, itemid, num)
    local t = assert(data.type_item[itemid], string.format("Item %d not exist.", itemid))
    local pack = p.item
    for k, v in pairs(util.clone(t)) do
        local vi = v[1]
        local diff = num
        if diff > vi.num then
            diff = num
        end
        vi.num = vi.num - diff
        num = num - diff
        local pi = {
            id = vi.id,
            num = vi.num,
        }
        if vi.num == 0 then
            item.del(v)
            pi.status = vi.status
            pi.status_time = vi.status_time
        end
        pack[#pack+1] = pi
        if num == 0 then
            break
        end
    end
    assert(num==0, string.format("Item %d num %d insufficient.", itemid, num))
end

-- NOTICE: can't delete equip, gem and item that has stone
function item.del(i)
    local iv = i[1]
    assert(not i[3] or i[3].num==0, string.format("Item %d has stone.", iv.id))
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
end

function item.split(p, itemid)
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
                return i, false
            else
                local iv = i[1]
                assert(minnum > 1, string.format("Item %d num %d error.", iv.id, minnum))
                local pack = p.item
                iv.num = iv.num - 1
                pack[#pack+1] = {
                    id = iv.id,
                    num = iv.num,
                }
                local v = {
                    -- id = cs(item.gen_id),
                    id = item.gen_id(),
                    itemid = itemid,
                    owner = 0,
                    num = 1,
                    pos = 0,
                    host = 0,
                    intensify = 0,
                    status = base.ITEM_STATUS_NORMAL,
                    status_time = 0,
                    price = 0,
                }
                local si = item.add(v, i[2])
                data.user.item[v.id] = v
                return si, true
            end
        end
    end
end

function item.inlay(p, i, stoneitem, j)
    local si, new = item.split(p, stoneitem)
    if si then
        local iv = i[1]
        local st = assert(i[3], string.format("item %d slot not exist.", iv.id))
        local siv = si[1]
        siv.host = iv.id
        siv.pos = j
        si[4] = i
        item.del_from_type(si)
        assert(not st[j], string.format("item %d slot %d has stone.", iv.id, j))
        st[j] = si
        st.num = st.num + 1
        local pitem = p.item
        if new then
            pitem[#pitem+1] = siv
        else
            pitem[#pitem+1] = {
                id = siv.id, 
                host = siv.host, 
                pos = siv.pos,
            }
        end
        return true
    end
end

function item.uninlay(p, i, si, j)
    local iv = i[1]
    local st = assert(i[3], string.format("item %d slot not exist.", iv.id))
    local siv = si[1]
    siv.host = 0
    siv.pos = 0
    si[4] = nil
    item.add_to_type(si)
    st[j] = nil
    st.num = st.num - 1
    local pack = p.item
    pack[#pack+1] = {
        id = siv.id, 
        host = siv.host, 
        pos = siv.pos,
    }
end

function item.equip_prop(e, prop)
    local inprop = 1
    local indata = e[5]
    if indata then
        inprop = inprop + indata.proportion
    end
    local ed = e[2]
    for k, v in ipairs(base.PROP_NAME) do
        local ev = ed[v]
        if ev then
            prop[v] = prop[v] + ev * inprop
        end
    end
    local iv = e[1]
    local rand_prop = iv.rand_prop
    for j = 1, base.MAX_RAND_PROP do
        local randProp = rand_prop[j]
        if randProp.type > 0 then
            local pname = base.PROP_NAME[randProp.type]
            prop[pname] = prop[pname] + randProp.value / base.FLOAT_FACTOR
        end
    end
    local stone = e[3]
    if stone and stone.num > 0 then
        local slot = ed.needLv // 10
        for j = 1, slot do
            local s = stone[j]
            if s then
                local sd = s[2]
                for k, v in ipairs(base.PROP_NAME) do
                    local sv = sd[v]
                    if sv then
                        prop[v] = prop[v] + sv
                    end
                end
            end
        end
    end
end

----------------------------protocol process------------------------

function proc.use_item(msg)
    local i = data.item[msg.id]
    if not i then
        error{code = error_code.ITEM_NOT_EXIST}
    end
    local iv = i[1]
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
    local itemtype = idata.itemType
    if is_chest(itemtype) then
        local p = update_user()
        if idata.key > 0 then
            if item.count(idata.key) == 0 then
                error{code = error_code.ITEM_NUM_LIMIT}
            end
            item.del_by_itemid(p, idata.key, 1)
        end
        item.del(i)
        local pitem = p.item
        pitem[#pitem+1] = {
            id = iv.id,
            status = iv.status,
            status_time = iv.status_time,
        }
        local bonus = {}
        for k, v in ipairs(idata.chest) do
            bonus[k] = {rand_num=1, data=v}
        end
        new_rand.init(floor(skynet.time()))
        stage.get_bonus(bonus, p)
        return "update_user", {update=p}
    elseif is_equip(itemtype) then
        if iv.pos == msg.pos then
            error{code = error_code.ERROR_ITEM_POSITION}
        end
        if msg.pos > 0 and msg.pos~=idata.itemType-base.ITEM_TYPE_HEAD+1 then
            error{code = error_code.ERROR_ITEM_POSITION}
        end
        local p = update_user()
        item.use(p, i, msg.pos)
        task.update(p, base.TASK_COMPLETE_USE_ITEM, iv.itemid, 1)
        role.fight_point(p)
        return "update_user", {update=p}
    else
        error{code = error_code.ERROR_ITEM_TYPE}
    end
end

function proc.compound_item(msg)
    local d = itemdata[msg.itemid]
    if not d then
        error{code = error_code.ITEM_ID_NOT_EXIST}
    end
    -- if not is_material(d.itemType) then
    --     error{code = error_code.ERROR_ITEM_TYPE}
    -- end
    local compounditem = d.compos
    if compounditem == 0 then
        error{code = error_code.CAN_NOT_COMPOUND_ITEM}
    end
    local compounddata = assert(itemdata[compounditem], string.format("No item data %d.", compounditem))
    local num = item.count(msg.itemid)
    if msg.num and msg.num < num then
        num = msg.num
    end
    local comnum = num // 5
    if comnum == 0 then
        error{code = error_code.ITEM_NUM_LIMIT}
    end
    local edata = assert(expdata[compounddata.quality], string.format("No exp data %d.", compounddata.quality))
    local p = update_user()
    item.del_by_itemid(p, msg.itemid, comnum * 5)
    local mul = 1
    if edata.composTotalRatio > 0 then
        local r = random(edata.composTotalRatio)
        for k, v in ipairs(edata.composRatio) do
            if r <= v[1] then
                mul = v[2]
                break
            end
        end
    end
    item.add_by_itemid(p, comnum * mul, compounddata)
    task.update(p, base.TASK_COMPLETE_COMPOUND_ITEM, compounddata.quality, 1)
    return "update_user", {update=p, compound_crit=mul}
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
    if d.quality >= base.MAX_QUALITY then
        error{code = error_code.MAX_QUALITY}
    end
    if d.quality >= data.expdata.ImproveLimit then
        error{code = error_code.ROLE_LEVEL_LIMIT}
    end
    local iv = i[1]
    if iv.status ~= base.ITEM_STATUS_NORMAL then
        error{code = error_code.ERROR_ITEM_STATUS}
    end
    if d.compos == 0 then
        error{code == error_code.CAN_NOT_IMPROVE_ITEM}
    end
    local mat = d.compos + 1
    local numdata = d.needLvExp
    local num = numdata.ImproveMatNum
    local count = item.count(mat)
    if count < num then
        error{code = error_code.ITEM_NUM_LIMIT}
    end
    local improveitemid = iv.itemid + 1
    local idata = assert(itemdata[improveitemid], string.format("No item data %d.", improveitemid))
    local p = update_user()
    item.del_by_itemid(p, mat, num)
    local olditemid = iv.itemid
    item.change(i, improveitemid, idata)
    local pitem = p.item
    pitem[#pitem+1] = {
        id = iv.id, 
        itemid = improveitemid, 
        rand_prop = iv.rand_prop,
    }
    task.update(p, base.TASK_COMPLETE_IMPROVE_ITEM, idata.quality, 1)
    if iv.pos > 0 then
        role.fight_point(p)
    end
    return "update_user", {update=p}
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
    local user = data.user
    if d.needLv + 5 > user.level then
        error{code = error_code.ROLE_LEVEL_LIMIT}
    end
    local iv = i[1]
    if iv.status ~= base.ITEM_STATUS_NORMAL then
        error{code = error_code.ERROR_ITEM_STATUS}
    end
    local mat = d.compos
    if mat == 0 then
        error{code = error_code.CAN_NOT_UPGRADE_ITEM}
    end
    local numdata = d.needLvExp
    local num = numdata.UpgradeMatNum
    local count = item.count(mat)
    if count < num then
        error{code = error_code.ITEM_NUM_LIMIT}
    end
    local upgradeitemid = iv.itemid + 5000
    local udata = assert(itemdata[upgradeitemid], string.format("No item data %d.", upgradeitemid))
    local p = update_user()
    item.del_by_itemid(p, mat, num)
    local olditemid = iv.itemid
    item.change(i, upgradeitemid, udata)
    local pitem = p.item
    pitem[#pitem+1] = {
        id = iv.id, 
        itemid = upgradeitemid, 
        rand_prop = iv.rand_prop,
    }
    task.update(p, base.TASK_COMPLETE_UPGRADE_ITEM, udata.needLv, 1)
    if iv.pos > 0 then
        role.fight_point(p)
    end
    return "update_user", {update=p}
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
    if iv.pos > 0 then
        error{code = error_code.ITEM_IN_USE}
    end
    local st = i[3]
    if st and st.num > 0 then
        error{code = error_code.ITEM_HAS_STONE}
    end
    local mat = d.compos
    if mat == 0 then
        error{code = error_code.CAN_NOT_DECOMPOSE_ITEM}
    end
    local matdata = assert(itemdata[mat], string.format("No item data %d.", mat))
    local numdata = d.needLvExp
    local p = update_user()
    item.del(i)
    local num = numdata.DecomposeMatNum
    item.add_by_itemid(p, num, matdata)
    local pitem = p.item
    pitem[#pitem+1] = {
        id = iv.id,
        status = iv.status,
        status_time = iv.status_time,
    }
    task.update(p, base.TASK_COMPLETE_DECOMPOSE_ITEM, d.quality, 1)
    return "update_user", {update=p}
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
    local p = update_user()
    item.del_by_itemid(p, base.INTENSIFY_ITEM, 1)
    local pitem = p.item
    local r = random(base.RAND_FACTOR)
    if r <= idata.rate then
        iv.intensify = iv.intensify + 1
        i[5] = idata
        pitem[#pitem+1] = {
            id = iv.id,
            intensify = iv.intensify,
        }
        task.update(p, base.TASK_COMPLETE_INTENSIFY_ITEM, iv.intensify, 1)
        if iv.pos > 0 then
            role.fight_point(p)
        end
    else
        iv.intensify = iv.intensify - idata.punishIntensify
        assert(iv.intensify>=0, string.format("Punish intensify data %d error.", intensify))
        if iv.intensify > 0 then
            i[5] = assert(intensifydata[iv.intensify], string.format("No intensify data %d.", iv.intensify))
        else
            i[5] = nil
        end
        local update= {
            id = iv.id,
            intensify = iv.intensify,
        }
        local punishitem = iv.itemid
        local levelRand = random(base.RAND_FACTOR)
        if levelRand <= idata.levelRate then
            punishitem = punishitem - idata.punishLevel * 1000
        end
        local qualityRand = random(base.RAND_FACTOR)
        if qualityRand <= idata.qualityRate then
            punishitem = punishitem - idata.punishQuality
        end
        if punishitem ~= iv.itemid then
            local pdata = assert(itemdata[punishitem], string.format("No item data %d.", punishitem))
            local oldSlot = d.needLv // 10
            local newSlot = pdata.needLv // 10
            if newSlot < oldSlot then
                local st = i[3]
                if st and st.num > 0 then
                    for j = newSlot, oldSlot do
                        local si = st[j]
                        if si then
                            item.uninlay(p, i, si, j)
                        end
                    end
                end
            end
            item.change(i, punishitem, pdata)
            update.status = iv.status
            update.status_time = iv.status_time
        end
        pitem[#pitem+1] = update
        task.update(p, base.TASK_COMPLETE_INTENSIFY_ITEM_FAIL, 0, 1)
        if iv.pos > 0 then
            role.fight_point(p)
        end
    end
    return "update_user", {update=p}
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
    local slot = func.get_item_slot(d.needLv)
    local p = update_user()
    local stp = d.itemType - base.ITEM_TYPE_HEAD + base.ITEM_TYPE_BLUE_STONE
    if msg.pos and msg.stone then
        if msg.pos > slot then
            error{code = error_code.ITEM_LEVEL_LIMIT}
        end
        if st[msg.pos] then
            error{code = error_code.STONE_IN_POSITION}
        end
        local sd = itemdata[msg.stone]
        if not sd then
            error{code = error_code.ITEM_ID_NOT_EXIST}
        end
        if sd.itemType ~= stp then
            error{code = error_code.ERROR_ITEM_TYPE}
        end
        if item.count(msg.stone) == 0 then
            error{code = error_code.ITEM_NUM_LIMIT}
        end
        item.inlay(p, i, msg.stone, msg.pos)
    else
        for j = 1, slot do
            local si = st[j]
            if si then
                item.uninlay(p, i, si, j)
            end
        end
        local function inlay_all()
            local k = slot
            local stoneitem = func.gen_itemid(0, 0, stp, k)
            for j = 1, slot do
                while not item.inlay(p, i, stoneitem, j) do
                    k = k - 1
                    if k > 0 then
                        stoneitem = func.gen_itemid(0, 0, stp, k)
                    else
                        return
                    end
                end
            end
        end
        inlay_all()
    end
    task.update(p, base.TASK_COMPLETE_INLAY_ITEM, 0, 1)
    if iv.pos > 0 then
        role.fight_point(p)
    end
    return "update_user", {update=p}
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
    if not st then
        error{code = error_code.NO_STONE_IN_POSITION}
    end
    local si = st[msg.pos]
    if not si then
        error{code = error_code.NO_STONE_IN_POSITION}
    end
    local p = update_user()
    item.uninlay(p, i, si, msg.pos)
    task.update(p, base.TASK_COMPLETE_UNINLAY_ITEM, 0, 1)
    if iv.pos > 0 then
        role.fight_point(p)
    end
    return "update_user", {update=p}
end

return item
