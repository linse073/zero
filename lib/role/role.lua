local skynet = require "skynet"
local timer = require "timer"
local share = require "share"
local notify = require "notify"
local util = require "util"
local proc_queue = require "proc_queue"

local card
local friend
local item
local stage
local task
local gm
local rank

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local math = math
local floor = math.floor
local randomseed = math.randomseed
local random = math.random

local update_user = util.update_user
local merge_table = util.merge_table
local year_day = util.year_day
local day_time = util.day_time
local expdata
local npcdata
local propertydata
local error_code
local base
local config
local type_reward
local cs
local map_pos
local max_exp
local data
local module
local role = {}
local proc = {}
local role_mgr
local rank_mgr
local gm_level = skynet.getenv("gm_level")

skynet.init(function()
    expdata = share.expdata
    npcdata = share.npcdata
    propertydata = share.propertydata
    error_code = share.error_code
    base = share.base
    config = share.config
    type_reward = share.type_reward
    cs = share.cs
    map_pos = share.map_pos
    max_exp = share.max_exp
    role_mgr = skynet.queryservice("role_mgr")
    rank_mgr = skynet.queryservice("rank_mgr")
end)

function role.init_module()
    card = require "role.card"
    friend = require "role.friend"
    item = require "role.item"
    stage = require "role.stage"
    task = require "role.task"
    gm = require "role.gm"
    rank = require "role.rank"
    module = {card, friend, item, stage, task, gm, rank}
    for k, v in ipairs(module) do
        merge_table(proc, v.init_module())
    end
    return proc
end

function role.init(userdata)
    data = userdata
    data.heart_beat = 0
    timer.add_routine("heart_beat", role.heart_beat, 300)
    local server_mgr = skynet.queryservice("server_mgr")
    data.server = skynet.call(server_mgr, "lua", "get", data.serverid)
	-- you may load user data from database
    local master = skynet.queryservice("dbmaster")
    data.accdb = skynet.call(master, "lua", "get", "accountdb")
    data.userdb = skynet.call(master, "lua", "get", "userdb")
    local account = skynet.call(data.accdb, "lua", "get", data.userkey)
    if account then
        data.account = skynet.unpack(account)
    else
        data.account = {} -- save account after create user
    end
    for k, v in ipairs(data.account) do
        if not v.fight_point then
            v.fight_point = 0
        end
    end
    for k, v in ipairs(module) do
        v.init(data)
    end
    local now = floor(skynet.time())
    randomseed(now)
end

function role.exit()
    for k, v in ipairs(module) do
        v.exit()
    end
    timer.del_routine("save_role")
    timer.del_day_routine("update_day")
    timer.del_routine("heart_beat")
    local user = data.user
    if user then
        skynet.call(role_mgr, "lua", "logout", user.id)
        user.logout_time = floor(skynet.time())
    end
    notify.exit()
    role.save_routine()
    data = nil
end

local function update_day(user)
    user.arena_count = 0
    user.charge_arena = 0
    local update_sign_in = false
    local diff = day_time(floor(skynet.time())) - config.start_day
    if diff // base.DAY_SECOND % base.MAX_SIGN_IN == 0 then
        local sign_in = user.sign_in
        for i = 1, base.MAX_SIGN_IN do
            sign_in[i] = false
        end
        user.sign_in_day = 0
        update_sign_in = true
    end
    stage.update_day()
    return task.update_day(), update_sign_in
end

function role.update_day()
    local user = data.user
    if user then
        local pt, update_sign_in = update_day(user)
        notify.add("update_day", {task=pt, update_sign_in=update_sign_in})
    end
end

function role.save_routine()
    local user = data.user
    if user then
        skynet.call(data.accdb, "lua", "save", data.userkey, skynet.packstring(data.account))
        skynet.call(data.userdb, "lua", "save", user.id, skynet.packstring(user))
    end
end

function role.move_speed()
    return base.MOVE_SPEED
end

function role.heart_beat()
    if data.heart_beat == 0 then
        skynet.error(string.format("heart beat kick user %s.", data.id))
        skynet.call(data.gate, "lua", "kick", data.id) -- data is nil
    else
        data.heart_beat = 0
    end
end

function role.add_exp(p, exp)
    local user = data.user
    local oldExp = user.exp
    user.exp = user.exp + exp
    if user.exp > max_exp.HeroExp then
        user.exp = ed.HeroExp
    end
    if oldExp ~= user.exp then
        local oldLevel = user.level
        local newLevel = oldLevel
        while true do
            if user.exp < data.expdata.HeroExp then
                break
            end
            newLevel = newLevel + 1
            data.expdata = assert(expdata[newLevel], string.format("No exp data %d.", newLevel))
        end
        local puser = p.user
        puser.exp = user.exp
        if oldLevel ~= newLevel then
            user.level = newLevel
            data.suser.level = newLevel
            puser.level = newLevel
            local pid = data.npc.propertyId + newLevel
            data.property = assert(propertydata[pid], string.format("No property data %d.", pid))
            role.fight_point(p)
            task.update_level(p, oldLevel, newLevel)
            task.update(p, base.TASK_COMPLETE_LEVEL, 0, 0, newLevel)
            local rank_info = data.rank_info
            if rank_info then
                rank_info.level = newLevel
                skynet.send(rank_mgr, "lua", "update", rank_info)
            end
            local bmsg = {
                id = user.id,
                level = newLevel,
            }
            skynet.send(role_mgr, "lua", "broadcast_area", "update_other", bmsg)
        end
    end
end

function role.add_money(p, money)
    local user = data.user
    local puser = p.user
    user.money = user.money + money
    puser.money = user.money
    task.update(p, base.TASK_COMPLETE_MONEY, 0, 0, user.money)
end

function role.add_rmb(p, rmb)
    local user = data.user
    local puser = p.user
    user.rmb = user.rmb + rmb
    puser.rmb = user.rmb
    task.update(p, base.TASK_COMPLETE_RMB, 0, 0, user.rmb)
end

function role.fight_point(p)
    local user = data.user
    local puser = p.user
    role.init_prop()
    puser.fight_point = user.fight_point
    task.update(p, base.TASK_COMPLETE_FIGHT_POINT, 0, 0, user.fight_point)
end

local function get_reward(p, reward)
    if reward.rewardType == base.REWARD_TYPE_ITEM then
        item.add_by_itemid(p, 1, reward.item)
    elseif reward.rewardType == base.REWARD_TYPE_RMB then
        role.add_rmb(p, reward.reward)
    end
end
function role.sign_in(p, index)
    local user = data.user
    local puser = p.user
    user.sign_in[index] = true
    user.sign_in_day = user.sign_in_day + 1
    puser.sign_in_day = user.sign_in_day
    local reward = assert(type_reward[base.REWARD_ACTION_SIGN_IN][index], string.format("No sign in reward data %d.", index))
    get_reward(p, reward)
    local treward = type_reward[base.REWARD_ACTION_TOTAL_SIGN_IN][user.sign_in_day]
    if treward then
        get_reward(p, treward)
    end
    task.update(p, base.TASK_COMPLETE_SIGN_IN, 0, 1)
end

function role.calc_fight(prop)
    local fight_point = 0
    for k, v in pairs(prop) do
        local factor = base.PROP_FACTOR[k] or 1
        fight_point = fight_point + v * factor
    end
    return floor(fight_point)
end

function role.equip_fight(e)
    local prop = {}
    for k, v in ipairs(base.PROP_NAME) do
        prop[v] = 0
    end
    item.equip_prop(e, prop)
    return role.calc_fight(prop)
end

function role.init_prop()
    local user = data.user
    local propData = data.property
    local prop = {}
    for k, v in ipairs(base.PROP_NAME) do
        prop[v] = propData[v]
    end
    local equip = data.equip_item
    for i = 1, base.MAX_EQUIP do
        local e = equip[i]
        if e then
            item.equip_prop(e, prop)
        end
    end
    user.fight_point = role.calc_fight(prop)
    data.suser.fight_point = user.fight_point
    data.prop = prop
end

function role.repair(user)
    if not user.sign_in then
        local sign_in = {}
        for i = 1, base.MAX_SIGN_IN do
            sign_in[i] = false
        end
        user.sign_in = sign_in
    end
    if not user.sign_in_day then
        user.sign_in_day = 0
    end
end

-------------------protocol process--------------------------

function proc.notify_info(msg)
    return notify.send()
end

function proc.heart_beat(msg)
    data.heart_beat = data.heart_beat + 1
    return "heart_beat_response", {time=msg.time, server_time=skynet.time()*100}
end

function proc.get_account_info(msg)
    return "account_info", {user=data.account}
end

function proc.create_user(msg)
    local account = data.account
    if #account >= base.MAX_ROLE then
        error{code = error_code.MAX_ROLE}
    end
    if msg.prof < base.PROF_WARRIOR or msg.prof > base.PROF_WIZARD then
        error{code = error_code.PROFESSION_NOT_EXIST}
    end
    local roleid = skynet.call(data.server, "lua", "gen_role", msg.name)
    if roleid == 0 then
        error{code = error_code.ROLE_NAME_EXIST}
    end
    local su = {
        name = msg.name,
        id = roleid,
        prof = msg.prof,
        level = 1,
        fight_point = 0,
    }
    account[#account+1] = su
    skynet.call(data.accdb, "lua", "save", data.userkey, skynet.packstring(account))
    local initRect = base.INIT_RECT
    local x = random(initRect.x, initRect.ex)
    local y = random(initRect.y, initRect.ey)
    local sign_in = {}
    for i = 1, base.MAX_SIGN_IN do
        sign_in[i] = false
    end
    local u = {
        name = msg.name,
        id = roleid,
        prof = msg.prof,
        level = 1,
        exp = 0,
        charge = 0,
        vip = 0,
        rmb = 0,
        money = 0,
        arena_rank = 0,
        arena_count = 0,
        charge_arena = 0,
        fight_point = 0,
        login_time = 0,
        last_login_time = 0,
        logout_time = 0,
        gm_level = gm_level,
        cur_pos = {x=x, y=y},
        des_pos = {x=x, y=y},
        sign_in = sign_in,
        sign_in_day = 0,

        item = {},
        card = {},
        stage = {},
        task = {},
        friend = {},
    }
    skynet.call(data.userdb, "lua", "save", roleid, skynet.packstring(u))
    return "simple_user", su
end

local function enter_game(msg)
    -- if data.user then
    --     error{code = error_code.ROLE_ALREADY_ENTER}
    -- end
    local suser
    for k, v in ipairs(data.account) do
        if v.id == msg.id then
            suser = v
            break
        end
    end
    if not suser then
        error{code = error_code.ROLE_NOT_EXIST}
    end
    local user = skynet.call(data.userdb, "lua", "get", msg.id)
    if not user then
        error{code = error_code.ROLE_NOT_EXIST}
    end
    user = skynet.unpack(user)
    role.repair(user)
    local now = floor(skynet.time())
    user.last_login_time = user.login_time
    user.login_time = now
    data.suser = suser
    data.user = user
    if user.level > suser.level then
        suser.level = user.level
    end
    local npcID = base.PROF_NPC_BASE + user.prof
    local npc = assert(npcdata[npcID], string.format("No npc data %d.", npcID))
    data.npc = npc
    data.expdata = assert(expdata[user.level], string.format("No exp data %d.", user.level))
    local pid = npc.propertyId + user.level
    data.property = assert(propertydata[pid], string.format("No property data %d.", pid))
    local ret = {user = user}
    for k, v in ipairs(module) do
        if v.enter then
            local key, pack = v.enter()
            ret[key] = pack
        end
    end
    role.init_prop()
    if card.rank_card_full() then
        rank.add()
    end
    if user.logout_time > 0 then
        local od = year_day(user.logout_time)
        local nd = year_day(now)
        if od ~= nd then
            update_day(user)
        end
    end
    timer.add_routine("save_role", role.save_routine, 300)
    timer.add_day_routine("update_day", role.update_day)
    local stageid, seed = stage.newbie_stage()
    local bmsg = {
        name = user.name,
        id = user.id,
        prof = user.prof,
        level = user.level,
        cur_pos = user.cur_pos,
        des_pos = user.des_pos,
        fight = stageid ~= nil,
    }
    skynet.call(role_mgr, "lua", "enter", bmsg, skynet.self())
    return "info_all", {user=ret, start_time=config.start_time, stage_id=stageid, rand_seed=seed}
end
function proc.enter_game(msg)
    return proc_queue(cs, enter_game, msg)
end

function proc.move(msg)
    local user = data.user
    local des_pos = msg.des_pos
    map_pos(des_pos)
    user.des_pos.x = des_pos.x
    user.des_pos.y = des_pos.y
    user.cur_pos.x = des_pos.x
    user.cur_pos.y = des_pos.y
    local bmsg = {
        id = user.id,
        des_pos = des_pos,
    }
    skynet.send(role_mgr, "lua", "broadcast_area", "update_other", bmsg)
    return "response", ""
end

function proc.sign_in(msg)
    local diff = day_time(floor(skynet.time())) - config.start_day
    local index = diff // base.DAY_SECOND % base.MAX_SIGN_IN + 1
    assert(index<=base.MAX_SIGN_IN, string.format("Illegal sign in index %d.", index))
    local user = data.user
    local sign_in = user.sign_in
    local pindex
    if msg.patch then
        for i = 1, index do
            if not sign_in[i] then
                pindex = i
                break
            end
        end
        if not pindex then
            error{code = error_code.NO_PATCH_SIGN_IN}
        end
    else
        pindex = index
        if sign_in[pindex] then
            error{code = error_code.ALREADY_SIGN_IN}
        end
    end
    local p = update_user()
    role.sign_in(p, pindex)
    return "update_user", {update=p, sign_in=pindex}
end

return role
