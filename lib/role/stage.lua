local skynet = require "skynet"
local share = require "share"
local util = require "util"
local new_rand = require "random"

local role
local task
local item

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local math = math
local random = math.random
local floor = math.floor

local check_sign = util.check_sign
local update_user = util.update_user
local rand_num = new_rand.rand
local error_code
local base
local stagedata
local itemdata
local data
local role_mgr

local stage = {}
local proc = {}

skynet.init(function()
    error_code = share.error_code
    base = share.base
    stagedata = share.stagedata
    itemdata = share.itemdata
    role_mgr = skynet.queryservice("role_mgr")
end)

function stage.init_module()
    role = require "role.role"
    task = require "role.task"
    item = require "role.item"
    return proc
end

function stage.init(userdata)
    data = userdata
end

function stage.exit()
    data = nil
end

function stage.enter()
    local pack = {}
    data.stage = {}
    data.stage_seed = {
        id = 0,
        seed = 0,
    }
    for k, v in pairs(data.user.stage) do
        stage.add(v)
        pack[#pack+1] = v
    end
    return "stage", pack
end

function stage.add(v, d)
    if not d then
        d = assert(stagedata[v.id], string.format("No stage data %d.", v.id))
    end
    local s = {v, d}
    data.stage[v.id] = s
    return s
end

function stage.add_by_data(d)
    local v = {
        id = d.id,
        count = 0,
        time = 0,
        hit_score = 0,
        trap_score = 0,
        hp_score = 0,
    }
    local s = stage.add(v, d)
    data.user.stage[d.id] = v
    return s
end

function stage.update_day()
    for k, v in pairs(data.stage) do
        v[1].count = 0
    end
end

function stage.rand_bonus(d, sd)
    local user = data.user
    local rand = rand_num(d.total_rate)
    local t = 0
    for k, v in ipairs(d.all_rate) do
        t = t + v.rate
        if rand <= t then
            local bonus = {num=v.num, data=v.data}
            if v.type == base.BONUS_TYPE_EQUIP then
                local prof
                if v.prof == 1 then
                    prof = user.prof
                else
                    prof = rand_num(base.PROF_WARRIOR, base.PROF_WIZARD)
                end
                local level = v.level
                if level == 0 then
                    level = sd.limitLevel // 5 * 5
                end
                local itemtype = v.equipType
                if itemtype == 0 then
                    itemtype = rand_num(base.ITEM_TYPE_HEAD, base.ITEM_TYPE_NECKLACE)
                else
                end
                bonus.item = item.gen_itemid(prof, level, itemtype, v.quality)
            elseif v.type == base.BONUS_TYPE_MATERIAL then
                local itemtype = v.item_type
                if itemtype == 0 then
                    itemtype = rand_num(base.ITEM_TYPE_IRON, base.ITEM_TYPE_SPAR)
                end
                bonus.item = item.gen_itemid(0, 0, itemtype, v.quality)
            elseif v.type == base.BONUS_TYPE_STONE then
                local itemtype = v.item_type
                if itemtype == 0 then
                    itemtype = rand_num(base.ITEM_TYPE_BLUE_STONE, base.ITEM_TYPE_GREEN_CRYSTAL)
                end
                bonus.item = item.gen_itemid(0, 0, itemtype, v.quality)
            else
                bonus.item = v.item
            end
            return bonus
        end
    end
end

function stage.newbie_stage()
    local stageid = base.NEWBIE_STAGE
    local s = data.stage[stageid]
    if not s then
        local stage_seed = data.stage_seed
        stage_seed.id = stageid
        local seed = random(floor(skynet.time())+stageid)
        stage_seed.seed = seed
        return stageid, seed
    end
end

-----------------------------protocol process--------------------------

function proc.begin_stage(msg)
    local d = stagedata[msg.id]
    if not d then
        error{code = error_code.STAGE_ID_NOT_EXIST}
    end
    local user = data.user
    if user.level < d.limitLevel then
        error{code = error_code.ROLE_LEVEL_LIMIT}
    end
    if d.PreId ~= 0 then
        local ps = data.stage[d.PreId]
        if not ps then
            error{code = error_code.PRE_STAGE_NOT_COMPLETE}
        end
    end
    local s = data.stage[msg.id]
    if s then
        local sv = s[1]
        if sv.count >= d.limitCount then
            error{code = error_code.STAGE_COUNT_LIMIT}
        end
    end
    local stage_seed = data.stage_seed
    stage_seed.id = msg.id
    stage_seed.seed = random(floor(skynet.time())+msg.id)
    local bmsg = {
        id = user.id,
        fight = true,
    }
    skynet.send(role_mgr, "lua", "broadcast_area", "update_other", bmsg)
    return "stage_seed", {id=msg.id, rand_seed=stage_seed.seed}
end

function proc.end_stage(msg)
    local stage_seed = data.stage_seed
    if stage_seed.id ~= msg.id or stage_seed.seed ~= msg.rand_seed then
        error{code = error_code.ERROR_STAGE_SEED}
    end
    if not check_sign(msg, data.secret) then
        error{code = error_code.ERROR_STAGE_SIGN}
    end
    assert(msg.total_gold>=msg.pick_gold, string.format("error gold num, total %d, pick %d.", msg.total_gold, msg.pick_gold))
    local s = data.stage[msg.id]
    local d
    local money, exp
    local bonus = {}
    if s then
        d = s[2]
        money, exp = d.getMoney, d.getExp
        if d.bonus then
            bonus[#bonus+1] = {id=d.bonusID, rand_num=1, num={1}, data=d.bonus}
        end
    else
        d = assert(stagedata[msg.id], string.format("No stage data %d.", msg.id))
        s = stage.add_by_data(d)
        money, exp = d.firstMoney, d.firstExp
        if d.firstBonus then
            bonus[#bonus+1] = {id=d.firstBonusID, rand_num=1, num={1}, data=d.firstBonus}
        end
    end
    if msg.total_box then
        if d.dropBonus then
            bonus[#bonus+1] = {id=d.dropBonusID, rand_num=msg.total_box, num=msg.pick_box or {}, data=d.dropBonus}
        end
    end
    new_rand.init(msg.rand_seed)
    for k, v in ipairs(bonus) do
        local rand_item = {}
        for i = 1, v.rand_num do
            rand_item[i] = stage.rand_bonus(v.data, d)
        end
        v.rand_item = rand_item
    end
    local p = update_user()
    if money > 0 then
        role.add_money(p, money)
    end
    if exp > 0 then
        role.add_exp(p, exp)
    end
    if msg.total_gold > 0 and msg.pick_gold > 0 and d.goldTotal > 0 then
        role.add_money(p, d.goldTotal*msg.pick_gold//msg.total_gold)
    end
    for k, v in ipairs(bonus) do
        local rand_item = v.rand_item
        for k1, v1 in ipairs(v.num) do
            local ri = rand_item[v1]
            local itemid = ri.item
            local idata = ri.data
            if idata then
                item.add_by_itemid(p, ri.num, idata)
            else
                if itemid then
                    local rid = assert(itemdata[itemid], string.format("No item data %d.", itemid))
                    item.add_by_itemid(p, ri.num, rid)
                else
                    role.add_money(p, ri.num)
                end
            end
        end
    end
    local sv = s[1]
    sv.count = sv.count + 1
    if sv.time == 0 or msg.time < sv.time then
        sv.time = msg.time
    end
    if msg.hit_score > sv.hit_score then
        sv.hit_score = msg.hit_score
    end
    if msg.trap_score > sv.trap_score then
        sv.trap_score = msg.trap_score
    end
    if msg.hp_score > sv.hp_score then
        sv.hp_score = msg.hp_score
    end
    local pstage = p.stage
    pstage[#pstage+1] = sv
    task.update(p, base.TASK_COMPLETE_STAGE, msg.id, 1)
    task.update(p, base.TASK_COMPLETE_ELITE_STAGE, msg.id, 1)
    task.update(p, base.TASK_COMPLETE_STAGE_GUIDE, msg.id, 1)
    stage_seed.id = 0
    stage_seed.seed = 0
    local user = data.user
    local initRect = base.INIT_RECT
    local des_pos = user.des_pos
    des_pos.x = random(initRect.x, initRect.ex)
    des_pos.y = random(initRect.y, initRect.ey)
    user.cur_pos.x = des_pos.x
    user.cur_pos.y = des_pos.y
    p.user.des_pos = des_pos
    local bmsg = {
        id = user.id,
        fight = false,
        des_pos = des_pos,
    }
    skynet.send(role_mgr, "lua", "broadcast_area", "update_other", bmsg)
    return "update_user", {update=p}
end

return stage
