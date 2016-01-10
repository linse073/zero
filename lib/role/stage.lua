local skynet = require "skynet"
local share = require "share"
local util = require "util"

local role
local task

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local random = math.random
local randomseed = math.randomseed

local check_sign = util.check_sign
local update_user = util.update_user
local stagedata
local bonusdata
local data
local role_mgr

local stage = {}
local proc = {}

skynet.init(function()
    stagedata = share.stagedata
    bonusdata = share.bonusdata
    role_mgr = skynet.queryservice("role_mgr")

    role = require "role.role"
    task = require "role.task"
end)

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
        d = {v, assert(stagedata[v.id], string.format("No stage data %d.", v.id))}
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
    local rand = random(d.total_rate)
    local t = 0
    for k, v in ipairs(d.all_rate) do
        t = t + v.rate
        if rand <= t then
            local bonus = {num = v.num}
            if v.type == base.BONUS_TYPE_EQUIP then
                local prof
                if v.prof == 1 then
                    prof = user.prof
                else
                    prof = random(base.PROF_WARRIOR, base.PROF_WIZARD)
                end
                local level
                if v.level == 1 then
                    level = user.level // 5 * 5
                else
                    level = sd.limitLevel // 5 * 5
                end
                local itemtype = random(base.ITEM_TYPE_HEAD, base.ITEM_TYPE_NECKLACE)
                bonus.item = item.gen_itemid(prof, level, itemtype, v.quality)
            elseif v.type == base.BONUS_TYPE_MATERIAL then
                local itemtype = v.item_type
                if itemtype == 0 then
                    itemtype = random(base.ITEM_TYPE_IRON, base.ITEM_TYPE_SPAR)
                end
                bonus.item = item.gen_itemid(0, 0, itemtype, v.quality)
            elseif v.type == base.BONUS_TYPE_STONE then
                local itemtype = v.item_type
                if itemtype == 0 then
                    itemtype = random(base.ITEM_TYPE_BLUE_STONE, base.ITEM_TYPE_GREEN_CRYSTAL)
                end
                bonus.item = item.gen_itemid(0, 0, itemtype, v.quality)
            else
                bonus.item = v.item
            end
            return bonus
        end
    end
end

function stage.get_proc()
    return proc
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
    stage_seed.seed = random(skynet.time()+msg.id)
    local bmsg = {
        id = user.id,
        fight = true,
    }
    skynet.send(role_mgr, "lua", "broadcast_area", "other_info", bmsg)
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
    assert(msg.total_box>=msg.pick_box, string.format("error box num, total %d, pick %d.", msg.total_box, msg.pick_box))
    local s = data.stage[msg.id]
    local d
    local money, exp
    local bonus = {}
    if s then
        d = s[2]
        money, exp = d.getMoney, d.getExp
        bonus[#bonus+1] = {id=d.bonusID, rand_num=1, num=1}
    else
        d = assert(stagedata[msg.id], string.format("No stage data %d.", msg.id))
        s = stage.add_by_data(d)
        money, exp = d.firstMoney, d.firstExp
        bonus[#bonus+1] = {id=d.firstBonusID, rand_num=1, num=1}
    end
    if msg.total_box > 0 then
        bonus[#bonus+1] = {id=d.dropBonus, rand_num=msg.total_box, num=msg.pick_box}
    end
    randomseed(msg.rand_seed)
    for k, v in ipairs(bonus) do
        local rand_item = {}
        local bd = assert(bonusdata[v.id], string.format("No bonus data %d.", v.id))
        for i = 1, v.rand_num do
            rand_item[i] = stage.rand_bonus(bd, d)
        end
        v.rand_item = rand_item
    end
    randomseed(skynet.time())
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
        for i = 1, v.num do
            local ri = rand_item[i]
            local itemid = ri.item
            if itemid then
                local rid = assert(itemdata[itemid], string.format("No item data %d.", itemid))
                item.add_by_itemid(p, itemid, ri.num, rid)
            else
                role.add_money(p, ri.num)
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
    pstage[pstage+1] = sv
    task.update(p, base.TASK_COMPLETE_STAGE, msg.id, 1)
    stage_seed.id = 0
    stage_seed.seed = 0
    local des_pos = data.user.des_pos
    local initRect = base.INIT_RECT
    des_pos.x = random(initRect.x, initRect.ex)
    des_pos.y = random(initRect.y, initRect.ey)
    p.user.des_pos = des_pos
    local bmsg = {
        id = data.user.id,
        fight = false,
        des_pos = des_pos,
    }
    skynet.send(role_mgr, "lua", "broadcast_area", "other_info", bmsg)
    return "update_user", {update=p}
end

return stage
