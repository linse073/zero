local skynet = require "skynet"
local share = require "share"
local util = require "util"

local role = require "role.role"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local random = math.random
local randomseed = math.randomseed
local floor = math.floor

local check_sign = util.check_sign
local stagedata
local bonusdata
local data

local stage = {}
local proc = {}

skynet.init(function()
    stagedata = share.stagedata
    bonusdata = share.bonusdata
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

function stage.rand_bonus(id, num)
    local r = {}
    local d = assert(bonusdata[id], string.format("No bonus data %d.", id))
    for i = 1, num do
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
    return "stage_seed", {id=msg.id, rand_seed=random(skynet.time()+msg.id)}
end

function proc.end_stage(msg)
    if not check_sign(msg, data.secret) then
        error{code = error_code.ERROR_STAGE_SIGN}
    end
    assert(msg.total_gold>=msg.pick_gold, string.format("error gold num, total %d, pick %d.", msg.total_gold, msg.pick_gold))
    assert(msg.total_box>=msg.pick_box, string.format("error box num, total %d, pick %d.", msg.total_box, msg.pick_box))
    local s = data.stage[msg.id]
    local d
    local money, exp
    if s then
        d = s[2]
        money, exp = d.getMoney, d.getExp
    else
        d = assert(stagedata[msg.id], string.format("No stage data %d.", msg.id))
        s = stage.add_by_data(d)
        money, exp = d.firstMoney, d.firstExp
    end
    local puser = {}
    local ptask = {}
    local user = data.user
    if money > 0 then
        user.money = user.money + money
        puser.money = user.money
    end
    if exp > 0 then
        local pu, pt = role.add_exp(exp)
        if pu then
            merge_table(puser, pu)
            if pt then
                merge(ptask, pt)
            end
        end
    end
    if msg.total_gold > 0 and msg.pick_gold > 0 and d.goldTotal > 0 then
        user.money = user.money + floor(d.goldTotal * msg.pick_gold / msg.total_gold)
        puser.money = user.money
    end
    local sv = s[1]
    sv.count = sv.count + 1
    if msg.time < sv.time then
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
end

return stage
