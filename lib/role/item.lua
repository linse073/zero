local skynet = require "skynet"
local share = require "share"
local util = require "util"
local new_rand = require "random"
local func = require "func"
local proc_queue = require "proc_queue"
local notify = require "notify"

local task
local role
local stage
local mail

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local table = table
local math = math
local random = math.random
local floor = math.floor

local update_user = util.update_user
local itemdata
local expdata
local intensifydata
local malldata
local base
local error_code
local vip_level
local guild_store
local cs
local is_equip
local is_material
local is_chest
local item_category
local trade_mgr
local save_trade
local offline_mgr
local role_mgr
local task_rank
local data

local trade_title
local buy_content
local sell_content

local item = {}
local proc = {}

skynet.init(function()
    itemdata = share.itemdata
    expdata = share.expdata
    intensifydata = share.intensifydata
    malldata = share.malldata
    base = share.base
    error_code = share.error_code
    vip_level = share.vip_level
    guild_store = share.guild_store
    cs = share.cs
    is_equip = func.is_equip
    is_material = func.is_material
    is_chest = func.is_chest
    item_category = share.item_category
    trade_mgr = skynet.queryservice("trade_mgr")
    save_trade = skynet.queryservice("save_trade")
    offline_mgr = skynet.queryservice("offline_mgr")
    role_mgr = skynet.queryservice("role_mgr")
    task_rank = skynet.queryservice("task_rank")

    trade_title = func.get_string(198000004)
    buy_content = func.get_string(198000005)
    sell_content = func.get_string(198000006)
end)

function item.init_module()
    task = require "role.task"
    role = require "role.role"
    stage = require "role.stage"
    mail = require "role.mail"
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
    for k, v in pairs(data.user.item) do
        item.add(v)
    end
    item.after_add()
end

function item.pack_all()
    local user = data.user
    local pack = {}
    for k, v in pairs(user.item) do
        pack[#pack+1] = v
    end
    local sell_pack = skynet.call(trade_mgr, "lua", "role_item", user.id)
    for k, v in ipairs(sell_pack) do
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
    return i
end

function item.add_by_itemid(p, num, d)
    local itemid = d.id
    assert(num>0, string.format("Add item %d num error.", itemid))
    if d.itemType == base.ITEM_TYPE_AUTO_CHEST then
        local bonus = {}
        for k, v in ipairs(d.chest) do
            bonus[k] = {rand_num=num, data=v}
        end
        stage.get_bonus(bonus, p)
    else
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
            pack[#pack+1] = v
            num = num - diff
        end
    end
end

function item.add_by_info(v, d)
    v.status = base.ITEM_STATUS_NORMAL
    v.status_time = floor(skynet.time())
    item.add(v, d)
    data.user.item[v.id] = v
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
    local update_item = {}
    for k, v in pairs(t) do
        local vi = v[1]
        local diff = num
        if diff > vi.num then
            diff = vi.num
        end
        vi.num = vi.num - diff
        num = num - diff
        update_item[#update_item+1] = v
        if num == 0 then
            break
        end
    end
    for k, v in ipairs(update_item) do
        local vi = v[1]
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
    end
    assert(num==0, string.format("Item %d num %d insufficient.", itemid, num))
end

function item.del_by_id(p, i, num)
    local vi = i[1]
    assert(vi.num>=num, string.format("Error delete item %d num %d.", vi.num, num))
    local pack = p.item
    vi.num = vi.num - num
    local pi = {id=vi.id, num=vi.num}
    if vi.num == 0 then
        item.del(i)
        pi.status = vi.status
        pi.status_time = vi.status_time
    end
    pack[#pack+1] = pi
end

function item.sell_by_itemid(p, itemid, num, price)
    local t = assert(data.type_item[itemid], string.format("Item %d not exist.", itemid))
    local user = data.user
    local del_item = {}
    local ret_item = {}
    local pack = p.item
    local last_num
    for k, v in pairs(t) do
        local vi = v[1]
        if vi.num > num then
            local i = {
                id = item.gen_id(),
                itemid = itemid,
                owner = 0,
                num = vi.num - num,
                pos = 0,
                host = 0,
                intensify = 0,
                status = base.ITEM_STATUS_NORMAL,
                status_time = 0,
                price = 0,
            }
            item.add(i, v[2])
            user.item[i.id] = i
            pack[#pack+1] = i
            vi.num = num
            last_num = num
        end
        del_item[#del_item+1] = v
        ret_item[#ret_item+1] = vi
        num = num - vi.num
        if num == 0 then
            break
        end
    end
    for k, v in ipairs(del_item) do
        item.sell(p, v, price)
    end
    if last_num then
        pack[#pack].num = last_num
    end
    assert(num==0, string.format("Item %d num %d insufficient.", itemid, num))
    return ret_item
end

function item.sell(p, v, price)
    local user = data.user
    local vi = v[1]
    vi.owner = user.id
    vi.price = price
    item.del(v, base.ITEM_STATUS_SELL)
    local pack = p.item
    pack[#pack+1] = {
        id = vi.id,
        owner = vi.owner,
        price = vi.price,
        status = vi.status,
        status_time = vi.status_time,
    }
end

-- NOTICE: can't delete equip, gem and item that has stone
function item.del(i, status)
    if not status then
        status = base.ITEM_STATUS_DELETE
    end
    local iv = i[1]
    assert(not i[3] or i[3].num==0, string.format("Item %d has stone.", iv.id))
    assert(not i[4], string.format("Can't delete stone %d.", iv.id))
    assert(iv.pos==0, string.format("Can't delete equip %d.", iv.id))
    item.del_from_type(i)
    iv.status = status
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
        item.del_by_id(p, i, 1)
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
    local user = data.user
    local mul
    local total = 0
    if edata.composTotalRatio > 0 then
        local r = random(edata.composTotalRatio)
        local l = assert(vip_level[user.vip], string.format("No vip level %d.", user.vip))
        for i = 1, comnum do
            mul = 1
            for k, v in ipairs(edata.composRatio) do
                if r <= v[1] + l.composRate then
                    mul = v[2]
                    break
                end
            end
            total = total + mul
        end
    else
        total = comnum
    end
    item.add_by_itemid(p, total, compounddata)
    task.update(p, base.TASK_COMPLETE_COMPOUND_ITEM, compounddata.quality, total)
    if user.level >= base.WEEK_TASK_LEVEL then
        skynet.call(task_rank, "lua", "update", 4, user.id, total * floor(3 ^ (compounddata.quality - 2)))
    end
    if comnum == 1 then
        return "update_user", {update=p, compound_crit=mul}
    else
        return "update_user", {update=p}
    end
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
    local rate = idata.rate
    local user = data.user
    local l = assert(vip_level[user.vip], string.format("No vip level %d.", user.vip))
    rate = rate + l.intensifyRate
    if r <= rate then
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
            update.itemid = punishitem
            update.rand_prop = iv.rand_prop
            -- update.status = iv.status
            -- update.status_time = iv.status_time
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

local function sort(l, r)
    return l.price < r.price
end
-- TODO: split packet
function proc.query_sell(msg)
    local d = itemdata[msg.id]
    if not d then
        error{code = error_code.ITEM_ID_NOT_EXIST}
    end
    local p = skynet.call(trade_mgr, "lua", "query", msg.id)
    if d.officialSale == 1 and d.officialNumber1 > 0 and d.officialNumber2 > 0 and (d.PreId == 0 or data.stage[d.PreId]) then
        local user = data.user
        local t = user.trade_item[msg.id]
        if t then
            local t1 = t[1]
            local t2 = t[2]
            local ti = 1
            local len = #t1
            for i = 1, base.TRADE_PAGE_ITEM do
                local m
                while ti <= len do
                    local s = t1[ti]
                    ti = ti + 1
                    if s.num > 0 then
                        m = {
                            itemid = msg.id,
                            price = s.price,
                            num = s.num,
                        }
                        break
                    end
                end
                if not m then
                    local price = t1[len].price * random(d.priceUp1, d.priceUp2) // base.RAND_FACTOR
                    local count = random(d.officialNumber1, d.officialNumber2)
                    m = {
                        itemid = msg.id,
                        price = price,
                        num = count,
                    }
                    local n = {
                        price = price,
                        num = count,
                    }
                    len = len + 1
                    t1[len] = n
                    t2[price] = n
                    ti = len + 1
                end
                p[#p+1] = m
            end
        else
            local t1 = {}
            local t2 = {}
            local price = d.officialPrice
            local count = random(d.officialNumber1, d.officialNumber2)
            for i = 1, base.TRADE_PAGE_ITEM do
                p[#p+1] = {
                    itemid = msg.id,
                    price = price,
                    num = count,
                }
                local n = {
                    price = price,
                    num = count,
                }
                t1[i] = n
                t2[price] = n
                price = price * random(d.priceUp1, d.priceUp2) // base.RAND_FACTOR
                count = random(d.officialNumber1, d.officialNumber2)
            end
            t = {t1, t2}
            user.trade_item[msg.id] = t
        end
    end
    if d.overlay > 1 then
        table.sort(p, sort)
        local np = {}
        local pi
        local c = 0
        for k, v in ipairs(p) do
            if pi and pi.price == v.price then
                pi.num = pi.num + v.num
            else
                if c >= base.TRADE_PAGE_ITEM then
                    break
                end
                pi = v
                c = c + 1
                np[c] = pi
            end
        end
        p = np
    end
    return "query_sell_info", {id=msg.id, info=p}
end

function proc.sell_item(msg)
    if msg.id then
        local i = data.item[msg.id]
        if not i then
            error{code = error_code.ITEM_NOT_EXIST}
        end
        local iv = i[1]
        if iv.pos > 0 then
            error{code = error_code.ITEM_IN_USE}
        end
        local st = i[3]
        if st and st.num > 0 then
            error{code = error_code.ITEM_HAS_STONE}
        end
        local d = i[2]
        if d.playerSale == 0 then
            error{code = error_code.ITEM_CANNOT_SELL}
        end
        if msg.price < d.minPrice then
            error{code = error_code.LOWER_ITEM_PRICE}
        end
        if msg.price > d.maxPrice then
            error{code = error_code.HIGHER_ITEM_PRICE}
        end
        local p = update_user()
        local user = data.user
        proc_queue(cs, function()
            if user.money < 500 then
                error{code = error_code.ROLE_MONEY_LIMIT}
            end
            role.add_money(p, -500)
        end)
        item.sell(p, i, msg.price)
        skynet.call(trade_mgr, "lua", "add", iv, d)
        skynet.call(save_trade, "lua", "update", iv.id, iv)
        return "update_user", {update=p}
    elseif msg.itemid and msg.num then
        local d = itemdata[msg.itemid]
        if not d then
            error{code = error_code.ITEM_ID_NOT_EXIST}
        end
        if d.playerSale == 0 then
            error{code = error_code.ITEM_CANNOT_SELL}
        end
        if msg.price < d.minPrice then
            error{code = error_code.LOWER_ITEM_PRICE}
        end
        if msg.price > d.maxPrice then
            error{code = error_code.HIGHER_ITEM_PRICE}
        end
        local c = item.count(msg.itemid)
        if c < msg.num then
            error{code = error_code.ITEM_NUM_LIMIT}
        end
        local p = update_user()
        local user = data.user
        proc_queue(cs, function()
            if user.money < 500 then
                error{code = error_code.ROLE_MONEY_LIMIT}
            end
            role.add_money(p, -500)
        end)
        local is = item.sell_by_itemid(p, msg.itemid, msg.num, msg.price)
        skynet.call(trade_mgr, "lua", "batch_add", is, d)
        skynet.call(save_trade, "lua", "batch_update", is, true)
        return "update_user", {update=p}
    else
        error{code = error_code.ERROR_ARGS}
    end
end

function proc.back_item(msg)
    if msg.id then
        local i = skynet.call(trade_mgr, "lua", "get", msg.id)
        if not i then
            error{code = error_code.NO_SELL_ITEM}
        end
        local user = data.user
        local iv = i[1]
        if iv.owner ~= user.id then
            error{code = error_code.ITEM_NOT_EXIST}
        end
        if skynet.call(trade_mgr, "lua", "del", msg.id) == 0 then
            error{code = error_code.NO_SELL_ITEM}
        end
        skynet.call(save_trade, "lua", "update", iv.id, false)
        item.add_by_info(iv, i[2])
        local p = update_user()
        p.item[1] = {
            id = iv.id,
            status = iv.status,
            status_time = iv.status_time,
        }
        return "update_user", {update=p}
    elseif msg.itemid and msg.price then
        local d = itemdata[msg.itemid]
        if not d then
            error{code = error_code.ITEM_ID_NOT_EXIST}
        end
        local user = data.user
        local is = skynet.call(trade_mgr, "lua", "del_by_role", msg.itemid, user.id, msg.price)
        if #is == 0 then
            error{code = error_code.NO_SELL_ITEM}
        end
        skynet.call(save_trade, "lua", "batch_update", is, false)
        local p = update_user()
        local pack = p.item
        for k, v in ipairs(is) do
            item.add_by_info(v, d)
            pack[#pack+1] = {
                id = v.id,
                status = v.status,
                status_time = v.status_time,
            }
        end
        return "update_user", {update=p}
    else
        error{code = error_code.ERROR_ARGS}
    end
end

local function buy_update(r, id, num, u)
    local t = r[id]
    if t then
        t[1] = t[1] + num
        local t2 = t[2]
        t2[#t2+1] = u
    else
        t = {num, {u}}
        r[id] = t
    end
end
local function get_tax(price)
    local tax
    if price > 10000 then
        tax = 3000
        if price > 50000 then
            tax = tax + 14000
            tax = tax + (price - 50000) * 4 // 10
        else
            tax = tax + (price - 10000) * 35 // 100
        end
    else
        tax = price * 3 // 10
    end
    return tax
end
function proc.buy_item(msg)
    if msg.id then
        local i = skynet.call(trade_mgr, "lua", "get", msg.id)
        if not i then
            error{code = error_code.NO_SELL_ITEM}
        end
        local user = data.user
        local iv = i[1]
        if iv.owner == user.id then
            error{code = error_code.BUY_SELF_ITEM}
        end
        local total_price = iv.price * iv.num
        local p = update_user()
        proc_queue(cs, function()
            if user.money < total_price then
                error{code = error_code.ROLE_MONEY_LIMIT}
            end
            if skynet.call(trade_mgr, "lua", "del", msg.id) == 0 then
                error{code = error_code.NO_SELL_ITEM}
            end
            role.add_money(p, -total_price)
        end)
        task.update(p, base.TASK_COMPLETE_TRADE, 1, 0, total_price)
        skynet.call(save_trade, "lua", "update", iv.id, false)
        local now = floor(skynet.time())
        local m = {
            type = base.MAIL_TYPE_TRADE,
            time = now,
            title = trade_title,
            content = buy_content,
            item_info = {iv},
        }
        mail.add(m, p)
        local tax = get_tax(iv.price)
        local om = {
            type = base.MAIL_TYPE_TRADE,
            time = now,
            title = trade_title,
            content = string.format(sell_content, tax*iv.num),
            item_info = {
                {itemid=base.MONEY_ITEM, num=(iv.price-tax)*iv.num},
            },
        }
        skynet.call(offline_mgr, "lua", "add", "mail", iv.owner, om)
        local agent = skynet.call(role_mgr, "lua", "get", iv.owner)
        if agent then
            local op = update_user()
            op.item[1] = {
                id = iv.id,
                status = base.ITEM_STATUS_DELETE,
            }
            skynet.call(agent, "lua", "notify", "update_user", {update=op})
        end
        msg.itemid = iv.itemid
        return "update_user", {update=p, buy_item=msg}
    elseif msg.itemid and msg.num and msg.price then
        local d = itemdata[msg.itemid]
        if not d then
            error{code = error_code.ITEM_ID_NOT_EXIST}
        end
        local p = update_user()
        local tn, del, ln, u
        local user = data.user
        proc_queue(cs, function()
            if user.money < msg.price * msg.num then
                error{code = error_code.ROLE_MONEY_LIMIT}
            end
            tn, del, ln, u = skynet.call(trade_mgr, "lua", "del_by_itemid", msg.itemid, msg.price, msg.num)
            if tn < msg.num then
                if d.officialSale == 1 and d.officialNumber1 > 0 and d.officialNumber2 > 0 and (d.PreId == 0 or data.stage[d.PreId]) then
                    local t = user.trade_item[msg.itemid]
                    if t then
                        local n = t[2][msg.price]
                        if n and n.num > 0 then
                            local diff = msg.num - tn
                            if diff > n.num then
                                diff = n.num
                            end
                            n.num = n.num - diff
                            tn = tn + diff
                        end
                    end
                end
            end
            if tn == 0 then
                error{code = error_code.NO_SELL_ITEM}
            end
            role.add_money(p, -tn*msg.price)
        end)
        local r = {}
        if del then
            skynet.call(save_trade, "lua", "batch_update", del, false)
            for k, v in ipairs(del) do
                buy_update(r, v.owner, v.num, {
                    id = v.id,
                    status = base.ITEM_STATUS_DELETE,
                })
            end
        end
        if u then
            skynet.call(save_trade, "lua", "update", u.id, u)
            buy_update(r, u.owner, ln, {
                id = u.id,
                num = u.num,
            })
        end
        local now = floor(skynet.time())
        local m = {
            type = base.MAIL_TYPE_TRADE,
            time = now,
            title = trade_title,
            content = buy_content,
            item_info = {
                {itemid=msg.itemid, num=tn},
            },
        }
        mail.add(m, p)
        local tax = get_tax(msg.price)
        for k, v in pairs(r) do
            local om = {
                type = base.MAIL_TYPE_TRADE,
                time = now,
                title = trade_title,
                content = string.format(sell_content, tax*v[1]),
                item_info = {
                    {itemid=base.MONEY_ITEM, num=(msg.price-tax)*v[1]},
                },
            }
            skynet.call(offline_mgr, "lua", "add", "mail", k, om)
            local agent = skynet.call(role_mgr, "lua", "get", k)
            if agent then
                skynet.call(agent, "lua", "notify", "update_user", {update={item=v[2]}})
            end
        end
        return "update_user", {update=p, buy_item=msg}
    else
        error{code = error_code.ERROR_ARGS}
    end
end

function proc.add_watch(msg)
    local user = data.user
    if user.trade_watch_count >= base.MAX_TRADE_WATCH then
        error{code = error_code.TRADE_WATCH_COUNT_LIMIT}
    end
    if user.trade_watch[msg.id] then
        error{code = error_code.ALREADY_TRADE_WATCH}
    end
    user.trade_watch[msg.id] = msg.id
    user.trade_watch_count = user.trade_watch_count + 1
    return "update_user", {update={trade_watch={msg.id}}, add_watch=true}
end

function proc.del_watch(msg)
    local user = data.user
    if not user.trade_watch[msg.id] then
        error{code = error_code.NO_TRADE_WATCH}
    end
    user.trade_watch[msg.id] = nil
    user.trade_watch_count = user.trade_watch_count - 1
    return "update_user", {update={trade_watch={msg.id}}, add_watch=false}
end

function proc.mall_item(msg)
    local md = malldata[msg.id]
    if not md then
        error{code = error_code.ERROR_MALL_ITEM}
    end
    local user = data.user
    if md.saleType == base.MALL_SALE_RANDOM_1 then
        if user.mall_random[base.MALL_SALE_RANDOM_1] ~= msg.id then
            error{code = error_code.ERROR_RANDOM_MALL}
        end
    elseif md.saleType == base.MALL_SALE_RANDOM_2 then
        if user.mall_random[base.MALL_SALE_RANDOM_2] ~= msg.id then
            error{code = error_code.ERROR_RANDOM_MALL}
        end
    end
    if md.minVip and md.maxVip then
        if not (user.vip >= md.minVip and user.vip <= md.maxVip) then
            error{code = error_code.ROLE_VIP_LIMIT}
        end
    end
    if not data.stage[md.preStage] then
        error{code = error_code.PRE_STAGE_NOT_COMPLETE}
    end
    local num = user.mall_count[msg.id] or 0
    if md.limitNum ~= 0 then
        local limitNum = md.limitNum
        local l = assert(vip_level[user.vip], string.format("No vip level %d.", user.vip))
        if md.type == base.MALL_TYPE_DAY then
            limitNum = limitNum + l.mallDay
        elseif md.type == base.MALL_TYPE_TIME then
            limitNum = limitNum + l.mallLimit
        end
        if num >= limitNum then
            error{code = error_code.MALL_COUNT_LIMIT}
        end
    end
    if md.type == base.MALL_TYPE_TIME then
        local now = floor(skynet.time())
        local nt = func.game_day(now) % 10
        if nt ~= 2 and nt ~= 3 then
            error{code = error_code.MALL_TIME_LIMIT}
        end
    end
    local p = update_user()
    if md.priceType == base.COST_TYPE_MONEY then
        proc_queue(cs, function()
            if user.money < md.price then
                error{code = error_code.ROLE_MONEY_LIMIT}
            end
            role.add_money(p, -md.price)
        end)
    elseif md.priceType == base.COST_TYPE_RMB then
        proc_queue(cs, function()
            if user.rmb < md.price then
                error{code = error_code.ROLE_RMB_LIMIT}
            end
            role.add_rmb(p, -md.price)
        end)
    else
        error{code = error_code.ERROR_COST_TYPE}
    end
    item.add_by_itemid(p, 1, md.data)
    local newnum = num + 1
    user.mall_count[msg.id] = newnum
    p.mall_count = {
        {id=msg.id, count=newnum},
    }
    return "update_user", {update=p}
end

function proc.guild_item(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local gi = guild_store[msg.id]
    if not gi then
        error{code = error_code.ERROR_GUILD_ITEM}
    end
    local user = data.user
    local num = user.guild_item[msg.id] or 0
    local limitNum = skynet.call(data.guild, "lua", "stock_count")
    if num >= limitNum then
        error{code = error_code.GUILD_ITEM_COUNT_LIMIT}
    end
    local p = update_user()
    local price = gi[2]
    proc_queue(cs, function()
        if user.contribute < price then
            error{code = error_code.ROLE_CONTRIBUTE_LIMIT}
        end
        role.add_contribute(p, -price)
    end)
    item.add_by_itemid(p, 1, gi[1])
    local newnum = num + 1
    user.guild_item[msg.id] = newnum
    p.guild_item = {
        {id=msg.id, count=newnum},
    }
    return "update_user", {update=p}
end

return item
