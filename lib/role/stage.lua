local skynet = require "skynet"
local share = require "share"
local util = require "util"
local new_rand = require "random"
local func = require "func"

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
local area_stage
local stage_reward
local data
local role_mgr

local stage = {}
local proc = {}

skynet.init(function()
    error_code = share.error_code
    base = share.base
    stagedata = share.stagedata
    itemdata = share.itemdata
    area_stage = share.area_stage
    stage_reward = share.stage_reward
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
    data.stage = {}
    data.stage_seed = {
        id = 0,
        seed = 0,
        bonus = false,
    }
    for k, v in pairs(data.user.stage) do
        stage.add(v)
    end
end

function stage.pack_all()
    local pack = {}
    for k, v in pairs(data.user.stage) do
        pack[#pack+1] = v
    end
    return "stage", pack
end

function stage.pack_award()
    local pack = {}
    for k, v in pairs(data.user.stage_award) do
        pack[#pack+1] = k
    end
    return "stage_award", pack
end

function stage.star(v)
    -- TODO calculate stage star
    v.star = 3
end

function stage.repair(v)
    if not v.star then
        stage.star(v)
    end
end

function stage.add(v, d)
    if not d then
        d = assert(stagedata[v.id], string.format("No stage data %d.", v.id))
    end
    stage.repair(v)
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
            local rid = assert(itemdata[itemid], string.format("No item data %d.", itemid))
            item.add_by_itemid(p, ri.num, rid)
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
        stage.star(sv)
        ps[#ps+1] = sv
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
        if d.limitCount > 0 and sv.count >= d.limitCount then
            error{code = error_code.STAGE_COUNT_LIMIT}
        end
    end
    local stage_seed = data.stage_seed
    stage_seed.id = msg.id
    stage_seed.seed = random(floor(skynet.time())+msg.id)
    stage_seed.data = d
    stage_seed.bonus = false
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
    local d = stage_seed.data
    local money, exp
    local bonus = {}
    if s then
        money, exp = d.getMoney, d.getExp
        if d.bonus then
            bonus[#bonus+1] = {rand_num=1, data=d.bonus}
        end
    else
        s = stage.add_by_data(d)
        money, exp = d.firstMoney, d.firstExp
        if d.firstBonus then
            bonus[#bonus+1] = {rand_num=1, data=d.firstBonus}
        end
    end
    if msg.total_box then
        if d.dropBonus then
            bonus[#bonus+1] = {rand_num=msg.total_box, num=msg.pick_box or 0, data=d.dropBonus}
        end
    end
    local user = data.user
    if d.bonus then
        if user.vip > 0 then
            bonus[#bonus+1] = {rand_num=1, data=d.bonus}
        else
            bonus[#bonus+1] = {rand_num=1, num=0, data=d.bonus}
        end
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
    stage.star(sv)
    local pstage = p.stage
    pstage[#pstage+1] = sv
    task.update(p, base.TASK_COMPLETE_STAGE, msg.id, 1)
    task.update(p, base.TASK_COMPLETE_ELITE_STAGE, msg.id, 1)
    task.update(p, base.TASK_COMPLETE_STAGE_GUIDE, msg.id, 1)
    -- local initRect = base.INIT_RECT
    -- local des_pos = user.des_pos
    -- des_pos.x = random(initRect.x, initRect.ex)
    -- des_pos.y = random(initRect.y, initRect.ey)
    -- user.cur_pos.x = des_pos.x
    -- user.cur_pos.y = des_pos.y
    -- p.user.des_pos = des_pos
    local bmsg = {
        id = user.id,
        fight = false,
        -- des_pos = des_pos,
    }
    skynet.send(role_mgr, "lua", "broadcast_area", "update_other", bmsg)
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
    if d.bonus then
        local bonus = {}
        local num = 0
        if d.moneyType > 0 then
            local user = data.user
            local cost = base.STAGE_BONUS_COST[d.moneyType]
            local fn = role["add_" .. cost]
            for i = 1, msg.pick_chest do
                local money = i * d.moneyNum
                if user[cost] >= money then
                    fn(p, -money)
                    num = num + 1
                else
                    break
                end
            end
        end
        bonus[#bonus+1] = {rand_num=2, num=num, data=d.bonus}
        stage.get_bonus(bonus, p)
    end
    stage_seed.bonus = true
    return "update_user", {update=p}
end

function proc.stage_award(msg)
    local star = stage.area_star(msg.area)
    if star < 15 then
        error{code = error_code.STAGE_STAR_LIMIT}
    end
    local reward = stage_reward[msg.area]
    if not reward then
        error{code = error_code.ERROR_STAGE_AREA}
    end
    local user = data.user
    if user.stage_award[msg.area] then
        error{code = error_code.ALREADY_GET_STAGE_AWRAD}
    end
    local p = update_user()
    p.user.stage_award = {msg.area}
    role.get_reward(p, reward)
    return "update_user", {update=p}
end

return stage
