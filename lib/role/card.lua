local skynet = require "skynet"
local share = require "share"
local util = require "util"

local item
local task
local role

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string

local update_user = util.update_user
local carddata
local expdata
local passivedata
local original_card
local base
local error_code
local cs
local data

local card = {}
local proc = {}

skynet.init(function()
    carddata = share.carddata
    expdata = share.expdata
    passivedata = share.passivedata
    original_card = share.original_card
    base = share.base
    error_code = share.error_code
    cs = share.cs
end)

function card.init_module()
    item = require "role.item"
    task = require "role.task"
    role = require "role.role"
    return proc
end

function card.init(userdata)
    data = userdata
end

function card.exit()
    data = nil
end

function card.enter()
    local pack = {}
    data.card = {}
    local ec = {}
    data.equip_card = ec
    for i = 1, base.MAX_CARD_POSITION_TYPE do
        ec[i] = {}
    end
    data.type_card = {}
    for k, v in pairs(data.user.card) do
        card.add(v)
        pack[#pack+1] = v
    end
    return "card", pack
end

function card.add_to_type(c)
    local v = c[1]
    local original = original_card[v.cardid]
    local type_card = data.type_card
    assert(not type_card[original], string.format("Already has card %d original %d.", v.cardid, original))
    type_card[original] = v
end

function card.add(v, d)
    if not d then
        d = assert(carddata[v.cardid], string.format("No card data %d.", v.cardid))
    end
    local ps = {}
    for k, v in ipairs(v.passive_skill) do
        ps[v.id] = {
            v,
            assert(passivedata[v.id]. string.format("No passive data %d.", v.id)),
            assert(expdata[v.level], string.format("No exp data %d.", v.level)),
        }
    end
    local c = {v, d, ps}
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
        }
    end
    local v = {
        id = cs(card.gen_id),
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
    item.del_by_itemid(p, d.soulId, num)
    local pcard = p.card
    cv.level = cv.level + 1
    pcard[#pcard+1] = {
        id = cv.id,
        level = cv.level,
    }
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
    local money = ps[3].passiveGold
    local user = data.user
    if user.money < money then
        error{code = error_code.ROLE_MONEY_LIMIT}
    end
    local p = update_user()
    role.add_money(p, money)
    local si = ps[1]
    si.level = si.level + 1
    ps[3] = assert(expdata[si.level], string.format("No exp data %d.", si.level))
    local pcard = p.card
    pcard[#pcard+1] = {
        id = msg.id,
        passive_skill = si,
    }
    task.update(p, base.TASK_COMPLETE_UPGRADE_PASSIVE, si.id, 1)
    return "update_user", {update=p}
end

return card
