local skynet = require "skynet"
local share = require "share"
local util = require "util"
local func = require "func"

local item
local task
local role
local rank

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local math = math
local random = math.random

local update_user = util.update_user
local carddata
local expdata
local passivedata
local itemdata
local original_card
local base
local error_code
-- local cs
local data

local card = {}
local proc = {}

skynet.init(function()
    carddata = share.carddata
    expdata = share.expdata
    passivedata = share.passivedata
    itemdata = share.itemdata
    original_card = share.original_card
    base = share.base
    error_code = share.error_code
    -- cs = share.cs
end)

function card.init_module()
    item = require "role.item"
    task = require "role.task"
    role = require "role.role"
    rank = require "role.rank"
    return proc
end

function card.init(userdata)
    data = userdata
end

function card.exit()
    data = nil
end

function card.enter()
    data.card = {}
    local ec = {}
    data.equip_card = ec
    for i = 1, base.MAX_CARD_POSITION_TYPE do
        ec[i] = {}
    end
    data.type_card = {}
    for k, v in pairs(data.user.card) do
        card.add(v)
    end
    card.add_newbie_card(base.NEWBIE_CARD)
end

function card.pack_all()
    local pack = {}
    for k, v in pairs(data.user.card) do
        pack[#pack+1] = v
    end
    return "card", pack
end

function card.add_newbie_card(cardid)
    if not card.get_by_cardid(cardid) then
        local d = assert(carddata[cardid], string.format("No card data %d.", cardid))
        local pos = {}
        for i = 1, base.MAX_CARD_POSITION_TYPE do
            pos[i] = 0
        end
        local ec = data.equip_card[1]
        for i = 1, base.MAX_EQUIP_CARD do
            if not ec[i] then
                pos[1] = i
                break
            end
        end
        local passive_skill = {}
        for k, v in ipairs(d.passive) do
            passive_skill[k] = {
                id = v.id,
                level = 1,
                exp = 0,
                status = 0,
            }
        end
        local v = {
            -- id = cs(card.gen_id),
            id = card.gen_id(),
            cardid = cardid,
            level = d.starLv,
            pos = pos,
            passive_skill = passive_skill,
        }
        card.add(v, d)
        data.user.card[v.id] = v
    end
end

function card.rank_card_full()
    local ec = data.equip_card[1]
    for i = 1, base.MAX_EQUIP_CARD do
        if not ec[i] then
            return false
        end
    end
    return true
end

function card.rank_card()
    local info = {}
    local ec = data.equip_card[1]
    for i = 1, base.MAX_EQUIP_CARD do
        local c = ec[i]
        if c then
            info[#info+1] = c[4]
        end
    end
    return info
end

function card.add_to_type(c)
    local v = c[1]
    local original = original_card[v.cardid]
    local type_card = data.type_card
    assert(not type_card[original], string.format("Already has card %d original %d.", v.cardid, original))
    type_card[original] = v
end

function card.repair(v)
    for k1, v1 in ipairs(v.passive_skill) do
        if not v1.exp then
            v1.exp = 0
        end
        if not v1.status then
            v1.status = 0
        end
    end
end

function card.add(v, d)
    if not d then
        d = assert(carddata[v.cardid], string.format("No card data %d.", v.cardid))
    end
    card.repair(v)
    local ps = {}
    for k1, v1 in ipairs(v.passive_skill) do
        local edata = assert(expdata[v1.level], string.format("No exp data %d.", v1.level))
        local expitem = func.gen_itemid(0, 0, d.cardAttr+base.ITEM_TYPE_CARD_EXP_BEGIN, edata.passiveItem)
        ps[v1.id] = {
            v1,
            assert(passivedata[v1.id], string.format("No passive data %d.", v1.id)),
            edata,
            assert(itemdata[expitem], string.format("No item data %d.", expitem)),
        }
    end
    local sv = {
        id = v.id,
        cardid = v.cardid,
        level = v.level,
        pos = v.pos[1],
    }
    local c = {v, d, ps, sv}
    data.card[v.id] = c
    card.add_to_type(c)
    for i = 1, base.MAX_CARD_POSITION_TYPE do
        local pos = v.pos[i]
        if pos > 0 then
            local equip_card = data.equip_card[i]
            local ec = equip_card[pos]
            if ec then
                skynet.error(string.format("Already equip card %d in position %d, %d.", ec[1].id, i, pos))
                v.pos[i] = 0
            else
                equip_card[pos] = c
            end
        end
    end
    return c
end

function card.gen_id()
    return skynet.call(data.server, "lua", "gen_card")
end

function card.add_by_cardid(p, d)
    local pos = {}
    for i = 1, base.MAX_CARD_POSITION_TYPE do
        pos[i] = 0
    end
    local passive_skill = {}
    for k, v in ipairs(d.passive) do
        passive_skill[k] = {
            id = v.id,
            level = 1,
            exp = 0,
            status = 0,
        }
    end
    local v = {
        -- id = cs(card.gen_id),
        id = card.gen_id(),
        cardid = d.id,
        level = d.starLv,
        pos = pos,
        passive_skill = passive_skill,
    }
    local c = card.add(v, d)
    data.user.card[v.id] = v
    local pack = p.card
    pack[#pack+1] = v
    return c
end

function card.get_by_cardid(cardid)
    local original = original_card[cardid]
    return data.type_card[original]
end

-- NOTICE: pos can be 0
function card.use(p, c, pos_type, pos)
    local pack = p.card
    local cv = c[1]
    local equip_card = data.equip_card[pos_type]
    local oc = equip_card[pos]
    if oc then
        local opos = cv.pos[pos_type]
        local ocv = oc[1]
        ocv.pos[pos_type] = opos
        if opos > 0 then
            equip_card[opos] = oc
        end
        pack[#pack+1] = {id=ocv.id, pos=ocv.pos}
    end
    cv.pos[pos_type] = pos
    if pos > 0 then
        equip_card[pos] = c
    end
    pack[#pack+1] = {id=cv.id, pos=cv.pos}
end

--------------------------protocol process-----------------------

function proc.call_card(msg)
    local d = carddata[msg.cardid]
    if not d then
        error{code = error_code.CARD_ID_NOT_EXIST}
    end
    if d.cardType ~= base.CARD_TYPE_NORMAL then
        error{code = error_code.CARD_CAN_NOT_CALL}
    end
    local c = card.get_by_cardid(msg.cardid)
    if c then
        error{code = error_code.ALREADY_HAS_CARD}
    end
    local ed = d.starLvExp
    local count = item.count(d.soulId)
    if count < ed.cardStar then
        error{code = error_code.CARD_SOUL_LIMIT}
    end
    local p = update_user()
    item.del_by_itemid(p, d.soulId, ed.cardStar)
    card.add_by_cardid(p, d)
    task.update(p, base.TASK_COMPLETE_CARD, msg.cardid, 1)
    return "update_user", {update=p}
end

function proc.upgrade_card(msg)
    local c = data.card[msg.id]
    if not c then
        error{code = error_code.CARD_NOT_EXIST}
    end
    local cv = c[1]
    if cv.level >= base.MAX_CARD_STAR_LEVEL then
        error{code = error_code.MAX_CARD_STAR_LEVEL}
    end
    local ced = assert(expdata[cv.level], string.format("No exp data %d.", cv.level))
    local nextlevel = cv.level + 1
    local ned = assert(expdata[nextlevel], string.format("No exp data %d.", nextlevel))
    local num = ned.cardStar - ced.cardStar
    local d = c[2]
    local count = item.count(d.soulId)
    if count < num then
        error{code = error_code.CARD_SOUL_LIMIT}
    end
    local p = update_user()
    local pc = {id=cv.id}
    if cv.level%5 == 0 and d.evolveId ~= 0 then
        local ecount = item.count(d.evolveItem)
        if ecount < d.evolveNum then
            error{code = error_code.CARD_EVOLVE_ITEM_LIMIT}
        end
        local nd = assert(carddata[d.evolveId], string.format("No card data %d.", d.evolveId))
        item.del_by_itemid(p, d.evolveItem, d.evolveNum)
        cv.cardid = d.evolveId
        c[2] = nd
        c[4].cardid = cv.cardid
        pc.cardid = cv.cardid
    end
    item.del_by_itemid(p, d.soulId, num)
    cv.level = cv.level + 1
    c[4].level = cv.level
    pc.level = cv.level
    local pcard = p.card
    pcard[#pcard+1] = pc
    task.update(p, base.TASK_COMPLETE_UPGRADE_CARD, cv.cardid, 1)
    return "update_user", {update=p}
end

function proc.promote_card(msg)
    local c = data.card[msg.id]
    if not c then
        error{code = error_code.CARD_NOT_EXIST}
    end
    local d = c[2]
    if d.evolveId == 0 then
        error{code = error_code.CARD_CAN_NOT_EVOLVE}
    end
    local count = item.count(d.evolveItem)
    if count < d.evolveNum then
        error{code = error_code.CARD_EVOLVE_ITEM_LIMIT}
    end
    local p = update_user()
    item.del_by_itemid(p, d.evolveItem, d.evolveNum)
    local cv = c[1]
    local pcard = p.card
    cv.cardid = d.evolveId
    c[4].cardid = cv.cardid
    pcard[#pcard+1] = {
        id = cv.id,
        cardid = cv.cardid,
    }
    task.update(p, base.TASK_COMPLETE_PROMOTE_CARD, cv.cardid, 1)
    return "update_user", {update=p}
end

function proc.use_card(msg)
    local c = data.card[msg.id]
    if not c then
        error{code = error_code.CARD_NOT_EXIST}
    end
    if msg.pos_type <= 0 or msg.pos_type > base.MAX_CARD_POSITION_TYPE then
        error{code = error_code.ERROR_CARD_POSITION_TYPE}
    end
    if msg.pos < 0 or msg.pos > base.MAX_EQUIP_CARD then
        error{code = error_code.ERROR_CARD_POSITION}
    end
    local cv = c[1]
    if cv.pos[msg.pos_type] == msg.pos then
        error{code = error_code.ERROR_CARD_POSITION}
    end
    local p = update_user()
    card.use(p, c, msg.pos_type, msg.pos)
    if msg.pos_type == 1 then
        local info = data.rank_info
        info.card = card.rank_card()
        if info.arena_rank == 0 and card.rank_card_full() then
            p.user.arena_rank = rank.add()
        end
    end
    task.update(p, base.TASK_COMPLETE_USE_CARD, cv.cardid, 1)
    return "update_user", {update=p}
end

function proc.upgrade_passive(msg)
    local c = data.card[msg.id]
    if not c then
        error{code = error_code.CARD_NOT_EXIST}
    end
    local ps = c[3][msg.skillid]
    if not ps then
        error{code = error_code.CARD_NO_PASSIVE_SKILL}
    end
    local si = ps[1]
    local user = data.user
    if si.level >= user.level then
        error{code = error_code.ROLE_LEVEL_LIMIT}
    end
    local idata = ps[4]
    if item.count(idata.id) == 0 then
        error{code = error_code.ITEM_NUM_LIMIT}
    end
    local p = update_user()
    local mul = 1
    if msg.rmb and si.status > 0 then
        local rmb = idata.price * si.status
        if user.rmb < rmb then
            error{code = error_code.ROLE_RMB_LIMIT}
        end
        role.add_rmb(p, -rmb)
        mul = 10 * si.status
        si.status = 0
    end
    item.del_by_itemid(p, idata.id, 1)
    si.exp = si.exp + idata.exp * mul
    local olditem = ps[3].passiveItem
    while true do
        if si.exp < ps[3].passiveExp then
            break
        end
        si.level = si.level + 1
        ps[3] = assert(expdata[si.level], string.format("No exp data %d.", si.level))
    end
    local newitem = ps[3].passiveItem
    if olditem ~= newitem then
        local itemid = func.gen_itemid(0, 0, d.cardAttr+base.ITEM_TYPE_CARD_EXP_BEGIN, newitem)
        ps[4] = assert(itemdata[itemid], string.format("No item data %d.", itemid))
    end
    if mul == 1 and si.status == 0 then
        local r = random(base.RAND_FACTOR)
        if r <= 500 then
            si.status = 2
        elseif r <= 1500 then
            si.status = 1
        end
    end
    local pcard = p.card
    pcard[#pcard+1] = {
        id = msg.id,
        passive_skill = {si},
    }
    task.update(p, base.TASK_COMPLETE_UPGRADE_PASSIVE, si.level, 1)
    return "update_user", {update=p}
end

return card
