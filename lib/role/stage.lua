local skynet = require "skynet"
local share = require "share"
local util = require "util"
local new_rand = require "random"
local func = require "func"
local proc_queue = require "proc_queue"

local role
local task
local item

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local type = type
local string = string
local math = math
local random = math.random
local floor = math.floor

local check_sign = util.check_sign
local update_user = util.update_user
local randi = new_rand.randi
local error_code
local base
local stagedata
local itemdata
local expdata
local area_stage
local stage_reward
local stage_task_complete
local vip_level
local data
local role_mgr
local rank_mgr
local cs

local stage = {}
local proc = {}

skynet.init(function()
    error_code = share.error_code
    base = share.base
    stagedata = share.stagedata
    itemdata = share.itemdata
    expdata = share.expdata
    area_stage = share.area_stage
    stage_reward = share.stage_reward
    stage_task_complete = share.stage_task_complete
    vip_level = share.vip_level
    cs = share.cs
    role_mgr = skynet.queryservice("role_mgr")
    rank_mgr = skynet.queryservice("rank_mgr")
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
    data.stage = {}
    data.stage_seed = {
        id = 0,
        seed = 0,
        bonus = false,
        type = 0,
    }
    data.stage_star = 0
    for k, v in pairs(data.user.stage) do
        stage.add(v)
        data.stage_star = data.stage_star + v.star
    end
end

function stage.pack_all()
    local pack = {}
    for k, v in pairs(data.user.stage) do
        pack[#pack+1] = v
    end
    return "stage", pack
end

function stage.star(v, d)
    local star = 1
    if v.hp_score >= d.remainHp // 100 then
        star = star + 1
    end
    if v.time <= d.finishTime then
        star = star + 1
    end
    if not v.star or star > v.star then
        v.star = star
    end
end

function stage.repair(v, d)
    if not v.star then
        stage.star(v, d)
    end
end

function stage.add(v, d)
    if not d then
        d = assert(stagedata[v.id], string.format("No stage data %d.", v.id))
    end
    stage.repair(v, d)
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
        star = 0,
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

local function bonus_item(ri, p)
    local itemid = ri.item
    local idata = ri.data
    if idata then
        item.add_by_itemid(p, ri.num, idata)
    else
        if itemid then
            if itemid == base.MONEY_ITEM then
                role.add_money(p, ri.num)
            elseif itemid == base.RMB_ITEM then
                role.add_rmb(p, ri.num)
            else
                local rid = assert(itemdata[itemid], string.format("No item data %d.", itemid))
                item.add_by_itemid(p, ri.num, rid)
            end
        else
            role.add_money(p, ri.num)
        end
    end
end
function stage.get_bonus(bonus, p)
    local user = data.user
    for k, v in ipairs(bonus) do
        local rand_item = {}
        for i = 1, v.rand_num do
            rand_item[i] = func.rand_bonus(v.data, user.prof)
        end
        v.rand_item = rand_item
    end
    for k, v in ipairs(bonus) do
        local rand_item = v.rand_item
        if v.num then
            if type(v.num) == "table" then
                for k1, v1 in ipairs(v.num) do
                    bonus_item(rand_item[v1], p)
                end
            else
                for i = 1, v.num do
                    bonus_item(rand_item[i], p)
                end
            end
        else
            for k1, v1 in ipairs(rand_item) do
                bonus_item(v1, p)
            end
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
        stage_seed.data = assert(stagedata[stageid], string.format("No stage data %d.", stageid))
        stage_seed.bonus = false
        return stageid, seed
    end
end

function stage.area_star(area)
    local star = 0
    local ss = area_stage[area]
    if ss then
        local ds = data.stage
        for k, v in ipairs(ss) do
            local s = ds[v.id]
            if s then
                star = star + s[1].star
            end
        end
    end
    return star
end

function stage.chapter_star(stageType, chapter)
    local baseid = 1300000000 + stageType * 1000 + 10 * chapter
    local ds = data.stage
    local star = 0
    for i = 1, base.MAX_CHAPTER_STAGE do
        local s = ds[baseid + i]
        if s then
            star = star + s[1].star
        else
            break
        end
    end
    return star
end

function stage.complete_area(area)
    local ss = area_stage[area]
    if ss then
        local ds = data.stage
        for k, v in ipairs(ss) do
            local s = ds[v.id]
            if not s then
                return false
            end
        end
    end
    return true
end

function stage.add_stage(p, id)
    local ps = p.stage
    local s = data.stage[id]
    if not s then
        local d = assert(stagedata[id], string.format("No stage data %d.", id))
        s = stage.add_by_data(d)
        local bonus = {}
        local money, exp = d.firstMoney, d.firstExp
        if d.firstBonus then
            bonus[#bonus+1] = {rand_num=1, data=d.firstBonus}
        end
        if d.dropBonus then
            bonus[#bonus+1] = {rand_num=3, data=d.dropBonus}
        end
        local user = data.user
        if d.bonus then
            if user.vip > 0 then
                bonus[#bonus+1] = {rand_num=1, data=d.bonus}
            else
                bonus[#bonus+1] = {rand_num=1, num=0, data=d.bonus}
            end
        end
        stage.get_bonus(bonus, p)
        if money > 0 then
            role.add_money(p, money)
        end
        if exp > 0 then
            role.add_exp(p, exp)
        end
        role.add_money(p, d.goldTotal)
        local sv = s[1]
        sv.count = sv.count + 1
        sv.time = d.finishTime
        sv.hp_score = 100
        stage.star(sv, d)
        ps[#ps+1] = sv
        data.stage_star = data.stage_star + sv.star
        local ss = skynet.call(rank_mgr, "lua", "get", base.RANK_SLAVE_STAGE)
        skynet.call(ss, "lua", "update", user.id, data.stage_star)
    end
end

function stage.finish()
    -- data.stage_seed = {
    --     id = 0,
    --     seed = 0,
    --     bonus = false,
    -- }
    local user = data.user
    local bmsg = {
        id = user.id,
        fight = false,
    }
    skynet.send(role_mgr, "lua", "broadcast_area", "update_other", bmsg)
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
        if d.limitCount > 0 and sv.count >= d.limitCount then
            error{code = error_code.STAGE_COUNT_LIMIT}
        end
    end
    local stage_seed = data.stage_seed
    stage_seed.id = msg.id
    stage_seed.seed = random(floor(skynet.time())+msg.id)
    stage_seed.data = d
    stage_seed.bonus = false
    stage_seed.type = base.STAGE_SEED_NORMAL
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
        error{code = error_code.ERROR_SIGN}
    end
    assert(msg.total_gold>=msg.pick_gold, string.format("error gold num, total %d, pick %d.", msg.total_gold, msg.pick_gold))
    local s = data.stage[msg.id]
    local d = stage_seed.data
    local money, exp
    local bonus = {}
    if s then
        money, exp = d.getMoney, d.getExp
        bonus[#bonus+1] = {rand_num=1, data=d.bonus}
    else
        s = stage.add_by_data(d)
        money, exp = d.firstMoney, d.firstExp
        bonus[#bonus+1] = {rand_num=1, data=d.firstBonus}
    end
    bonus[#bonus+1] = {rand_num=msg.total_box or 0, num=msg.pick_box or 0, data=d.dropBonus}
    local user = data.user
    if user.vip > 0 then
        bonus[#bonus+1] = {rand_num=1, data=d.bonus}
    else
        bonus[#bonus+1] = {rand_num=1, num=0, data=d.bonus}
    end
    new_rand.init(msg.rand_seed)
    local p = update_user()
    stage.get_bonus(bonus, p)
    if money > 0 then
        role.add_money(p, money)
    end
    if exp > 0 then
        role.add_exp(p, exp)
    end
    if msg.total_gold > 0 and msg.pick_gold > 0 and d.goldTotal > 0 then
        role.add_money(p, d.goldTotal*msg.pick_gold//msg.total_gold)
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
    local old_star = sv.star
    stage.star(sv, d)
    local pstage = p.stage
    pstage[#pstage+1] = sv
    task.update(p, base.TASK_COMPLETE_STAGE, msg.id, 1)
    task.update(p, base.TASK_COMPLETE_ELITE_STAGE_GUIDE, msg.id, 1)
    task.update(p, base.TASK_COMPLETE_STAGE_GUIDE, msg.id, 1)
    local area = msg.id % 10000 // 10
    if stage.complete_area(area) then
        task.update(p, base.TASK_COMPLETE_CHAPTER, area, 0, 1)
    end
    if msg.monster > 0 then
        task.update(p, base.TASK_COMPLETE_MONSTER, 1, msg.monster)
    end
    if msg.elite_monster > 0 then
        task.update(p, base.TASK_COMPLETE_MONSTER, 2, msg.elite_monster)
    end
    if msg.boss > 0 then
        task.update(p, base.TASK_COMPLETE_MONSTER, 3, msg.boss)
    end
    local ct = stage_task_complete[d.stageType]
    if ct then
        task.update(p, base.TASK_COMPLETE_STAGE_COUNT, ct, 1)
    end
    if msg.pick_box then
        task.update(p, base.TASK_COMPLETE_OPEN_CHEST, 0, #msg.pick_box)
    end
    if msg.pick_gold > 0 then
        task.update(p, base.TASK_COMPLETE_PICK_GOLD, 0, msg.pick_gold)
    end
    if old_star ~= sv.star then
        data.stage_star = data.stage_star - old_star + sv.star
        task.update(p, base.TASK_COMPLETE_STAGE_STAR, 0, 0, data.stage_star)
        local ss = skynet.call(rank_mgr, "lua", "get", base.RANK_SLAVE_STAGE)
        skynet.call(ss, "lua", "update", user.id, data.stage_star)
    end
    -- local initRect = base.INIT_RECT
    -- local des_pos = user.des_pos
    -- des_pos.x = random(initRect.x, initRect.ex)
    -- des_pos.y = random(initRect.y, initRect.ey)
    -- user.cur_pos.x = des_pos.x
    -- user.cur_pos.y = des_pos.y
    -- p.user.des_pos = des_pos
    -- local bmsg = {
    --     id = user.id,
    --     fight = false,
    --     -- des_pos = des_pos,
    -- }
    -- skynet.send(role_mgr, "lua", "broadcast_area", "update_other", bmsg)
    stage.finish()
    return "update_user", {update=p}
end

function proc.fight_fail(msg)
    stage.finish()
    local p = update_user()
    local stage_seed = data.stage_seed
    if stage_seed.type == base.STAGE_SEED_ARENA then
        if stage_seed.rank_type == base.RANK_ARENA then
            task.update(p, base.TASK_COMPLETE_ARENA, 3, 1)
        elseif stage_seed.rank_type == base.RANK_FIGHT_POINT then
            task.update(p, base.TASK_COMPLETE_MATCH, 3, 1)
        end
    end
    return "update_user", {update=p}
end

function proc.open_chest(msg)
    assert(msg.pick_chest<=base.MAX_EXTRA_STAGE_BONUS, string.format("error chest num %d.", msg.pick_chest))
    local stage_seed = data.stage_seed
    local d = stage_seed.data
    if not d then
        error{code = error_code.ERROR_STAGE_STATE}
    end
    if stage_seed.bonus then
        error{code = error_code.ALREADY_GET_STAGE_BONUS}
    end
    local p = update_user()
    local bonus = {}
    local num = 0
    if d.moneyType > 0 and msg.pick_chest > 0 then
        local user = data.user
        local cost = base.STAGE_BONUS_COST[d.moneyType]
        local fn = role["add_" .. cost]
        proc_queue(cs, function()
            for i = 1, msg.pick_chest do
                local money = i * d.moneyNum
                if user[cost] >= money then
                    fn(p, -money)
                    num = num + 1
                else
                    break
                end
            end
        end)
    end
    bonus[#bonus+1] = {rand_num=2, num=num, data=d.bonus}
    stage.get_bonus(bonus, p)
    stage_seed.bonus = true
    return "update_user", {update=p}
end

function proc.get_stage_award(msg)
    local star = stage.area_star(msg.area)
    if star < 15 then
        error{code = error_code.STAGE_STAR_LIMIT}
    end
    local reward = stage_reward[msg.area]
    if not reward then
        error{code = error_code.ERROR_STAGE_AREA}
    end
    local user = data.user
    local us = user.stage_award
    if us[msg.area] then
        error{code = error_code.ALREADY_GET_STAGE_AWRAD}
    end
    us[msg.area] = true
    local p = update_user()
    p.stage_award = {msg.area}
    role.get_reward(p, reward)
    return "update_user", {update=p}
end

function proc.revive(msg)
    local user = data.user
    local l = assert(vip_level[user.vip], string.format("No vip level %d.", user.vip))
    -- if user.revive_count >= base.MAX_REVIVE_COUNT then
    --     error{code = error_code.REVIVE_COUNT_LIMIT}
    -- end
    local count = user.revive_count + 1
    local p = update_user()
    if count > l.relive then
        local dc = count - l.relive
        local e = assert(expdata[dc], string.format("No exp data %d.", dc))
        proc_queue(cs, function()
            if user.rmb < e.revivePrice then
                error{code = error_code.ROLE_RMB_LIMIT}
            end
            role.add_rmb(p, -e.revivePrice)
        end)
    end
    local pu = p.user
    user.revive_count = count
    pu.revive_count = count
    return "update_user", {update=p}
end

return stage
