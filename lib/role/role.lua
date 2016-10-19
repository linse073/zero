local skynet = require "skynet"
local timer = require "timer"
local share = require "share"
local notify = require "notify"
local util = require "util"
local func = require "func"
local proc_queue = require "proc_queue"
local new_rand = require "random"

local card
local friend
local item
local stage
local task
local gm
local rank
local mail
local guild

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
local game_day
local expdata
local npcdata
local propertydata
local itemdata
local is_equip
local is_stone
local error_code
local base
local type_reward
local mall_sale
local mall_limit
local cs
local map_pos
local max_exp
local vip_level
local random_sale
local data
local module
local role = {}
local proc = {}
local role_mgr
local fight_point_rank
local explore_mgr
local offline_mgr
local trade_mgr
local rank_mgr
local gm_level = skynet.getenv("gm_level")
local start_utc_time = tonumber(skynet.getenv("start_utc_time"))

local charge_title
local charge_content

local action

skynet.init(function()
    expdata = share.expdata
    npcdata = share.npcdata
    propertydata = share.propertydata
    itemdata = share.itemdata
    is_equip = func.is_equip
    is_stone = func.is_stone
    error_code = share.error_code
    base = share.base
    type_reward = share.type_reward
    mall_sale = share.mall_sale
    mall_limit = share.mall_limit
    cs = share.cs
    map_pos = func.map_pos
    game_day = func.game_day
    max_exp = share.max_exp
    vip_level = share.vip_level
    random_sale = share.random_sale
    role_mgr = skynet.queryservice("role_mgr")
    fight_point_rank = skynet.queryservice("fight_point_rank")
    explore_mgr = skynet.queryservice("explore_mgr")
    offline_mgr = skynet.queryservice("offline_mgr")
    trade_mgr = skynet.queryservice("trade_mgr")
    rank_mgr = skynet.queryservice("rank_mgr")

    charge_title = func.get_string(198000007)
    charge_content = func.get_string(198000008)
end)

function role.init_module()
    card = require "role.card"
    friend = require "role.friend"
    item = require "role.item"
    stage = require "role.stage"
    task = require "role.task"
    gm = require "role.gm"
    rank = require "role.rank"
    mail = require "role.mail"
    guild = require "role.guild"
    module = {card, friend, item, stage, task, gm, rank, mail, guild}
    for k, v in ipairs(module) do
        merge_table(proc, v.init_module())
    end
    action = {
        mail = {
            add = mail.add,
            notify = mail.notify,
            get = mail.get,
        },
        friend = {
            add = friend.add,
            notify = friend.notify,
            get = friend.get,
        },
        guild = {
            join = guild.join,
        },
    }
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
    data.namedb = skynet.call(master, "lua", "get", "namedb")
    data.rankinfodb = skynet.call(master, "lua", "get", "rankinfodb")
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
    timer.del_second_routine("update_second")
    local user = data.user
    if user then
        skynet.call(role_mgr, "lua", "logout", user.id)
        user.logout_time = floor(skynet.time())
        role.save_friend()
        role.save_user()
    end
    notify.exit()
    data = nil
end

local function update_mall_random()
    local mr = {}
    local mall_random = data.user.mall_random
    for k, v in ipairs(random_sale) do
        local m = mall_sale[v]
        local r = m[random(#m)]
        mall_random[v] = r.id
        mr[#mr+1] = r.id
    end
    return mr
end

local function update_day(user, od, nd, owd, nwd)
    user.week_day = nwd
    user.arena_count = 0
    user.charge_arena = 0
    local update_sign_in = false
    if od // base.MAX_SIGN_IN ~= nd // base.MAX_SIGN_IN then
        local sign_in = user.sign_in
        for i = 1, base.MAX_SIGN_IN do
            sign_in[i] = false
        end
        user.sign_in_day = 0
        update_sign_in = true
    end
    user.trade_item = {}
    user.exchange_count = 0
    user.refresh_arena_cd = 0
    user.refresh_match_cd = 0
    user.offline_exp_count = 0
    user.revive_count = 0
    user.patch_sign_in = 0
    stage.update_day()
    local mld = mall_limit[base.MALL_LIMIT_DAY]
    local mall_count = user.mall_count
    for k, v in ipairs(mld) do
        mall_count[v.id] = nil
    end
    local mall_week = false
    if od // 7 ~= nd // 7 then
        local mlw = mall_limit[base.MALL_LIMIT_WEEK]
        for k, v in ipairs(mlw) do
            mall_count[v.id] = nil
        end
        mall_week = true
    end
    local mall_time = false
    if od // 10 ~= nd // 10 then
        local mlt = mall_limit[base.MALL_LIMIT_TIME]
        for k, v in ipairs(mlt) do
            mall_count[v.id] = nil
        end
        mall_time = true
    end
    return task.update_day(), update_sign_in, rank.update_day(), update_mall_random(), mall_week, mall_time
end

function role.update_day(od, nd, owd, nwd)
    local user = data.user
    local pt, update_sign_in, arena_award, mall_random, mall_week, mall_time = update_day(user, od, nd, owd, nwd)
    notify.add("update_day", {
        task = pt, 
        update_sign_in = update_sign_in, 
        arena_award = arena_award,
        mall_random = mall_random,
        mall_week = mall_week,
        mall_time = mall_time,
        week_day = user.week_day,
    })
end

function role.test_update_day()
    local now = floor(skynet.time())
    local nd = game_day(now)
    local nwd = util.week_time(now)
    local user = data.user
    local pt, update_sign_in, arena_award, mall_random, mall_week, mall_time = update_day(user, nd, nd, nwd, nwd)
    return "update_day", {
        task = pt, 
        update_sign_in = update_sign_in, 
        arena_award = arena_award,
        mall_random = mall_random,
        mall_week = mall_week,
        mall_time = mall_time,
        week_day = user.week_day,
    }
end

function role.update_second()
    local now = floor(skynet.time())
    local p = update_user()
    local rank_list = rank.update(p, now)
    local online_change = role.online_award(p, now)
    if rank_list or online_change then
        notify.add("update_user", {update=p, rank_list=rank_list})
    end
end

function role.save_user()
    local user = data.user
    skynet.call(data.accdb, "lua", "save", data.userkey, skynet.packstring(data.account))
    skynet.call(data.userdb, "lua", "save", user.id, skynet.packstring(user))
    skynet.call(data.rankinfodb, "lua", "save", user.id, skynet.packstring(data.rank_info))
end

function role.save_friend()
    local user = data.user
    for k, v in pairs(user.friend) do
        local ri, online = skynet.call(role_mgr, "lua", "get_rank_info", v.id)
        v.level = ri.level
        v.fight_point = ri.fight_point
        v.online = online
    end
end

function role.save_routine()
    friend.update()
    role.save_user()
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
        user.exp = max_exp.HeroExp
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
            data.rank_info.level = newLevel
            puser.level = newLevel
            local pid = data.npc.propertyId + newLevel
            data.property = assert(propertydata[pid], string.format("No property data %d.", pid))
            role.fight_point(p)
            task.update_level(p, oldLevel, newLevel)
            task.update(p, base.TASK_COMPLETE_LEVEL, 0, 0, newLevel)
            local sl = skynet.call(rank_mgr, "lua", "get", base.RANK_SLAVE_LEVEL)
            skynet.call(sl, "lua", "update", user.id, newLevel)
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
    if money < 0 then
        task.update(p, base.TASK_COMPLETE_USE_MONEY, 0, -money)
    end
end

function role.add_rmb(p, rmb)
    local user = data.user
    local puser = p.user
    user.rmb = user.rmb + rmb
    puser.rmb = user.rmb
    task.update(p, base.TASK_COMPLETE_RMB, 0, 0, user.rmb)
    if rmb < 0 then
        task.update(p, base.TASK_COMPLETE_USE_RMB, 0, -rmb)
    end
end

function role.fight_point(p)
    local user = data.user
    local puser = p.user
    role.init_prop()
    puser.fight_point = user.fight_point
    task.update(p, base.TASK_COMPLETE_FIGHT_POINT, 0, 0, user.fight_point)
    if user.arena_rank ~= 0 then
        skynet.send(fight_point_rank, "lua", "update", user.id, user.fight_point)
    end
    if data.explore then
        skynet.send(data.explore, "lua", "update", user.id, user.fight_point)
    end
    local sf = skynet.call(rank_mgr, "lua", "get", base.RANK_SLAVE_FIGHT)
    skynet.call(sf, "lua", "update", user.id, user.fight_point)
end

function role.get_reward(p, reward)
    if reward.rewardType == base.REWARD_TYPE_ITEM then
        item.add_by_itemid(p, reward.rewardNum, reward.item)
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
    role.get_reward(p, reward)
    local treward = type_reward[base.REWARD_ACTION_TOTAL_SIGN_IN][user.sign_in_day]
    if treward then
        role.get_reward(p, treward)
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
    data.rank_info.fight_point = user.fight_point
    data.prop = prop
end

function role.repair(user, now)
    local sign_in = user.sign_in
    if sign_in then
        for i = 1, base.MAX_SIGN_IN do
            if sign_in[i] == nil then
                sign_in[i] = false
            end
        end
    else
        sign_in = {}
        for i = 1, base.MAX_SIGN_IN do
            sign_in[i] = false
        end
        user.sign_in = sign_in
    end
    if not user.sign_in_day then
        user.sign_in_day = 0
    end
    if not user.stage_award then
        user.stage_award = {}
    end
    if not user.mail then
        user.mail = {}
    end
    if not user.trade_watch then
        user.trade_watch = {}
    end
    if not user.trade_watch_count then
        user.trade_watch_count = 0
    end
    if not user.trade_item then
        user.trade_item = {}
    end
    if not user.exchange_count then
        user.exchange_count = 0
    end
    if not user.online_award_count then
        user.online_award_count = 0
    end
    if not user.online_award_time then
        user.online_award_time = now
    end
    if not user.arena_cd then
        user.arena_cd = 0
    end
    if not user.refresh_arena_cd then
        user.refresh_arena_cd = 0
    end
    if not user.match_count then
        user.match_count = 0
    end
    if not user.match_cd then
        user.match_cd = 0
    end
    if not user.refresh_match_cd then
        user.refresh_match_cd = 0
    end
    if not user.match_role then
        user.match_role = {}
    end
    if not user.match_win then
        user.match_win = 0
    end
    if not user.mall_random then
        user.mall_random = {}
    end
    if not user.mall_count then
        user.mall_count = {}
    end
    if not user.arena_win then
        user.arena_win = 0
    end
    if not user.explore_award then
        user.explore_award = 0
    end
    if not user.offline_exp_time then
        user.offline_exp_time = now
    end
    if not user.offline_exp_count then
        user.offline_exp_count = 0
    end
    if not user.revive_count then
        user.revive_count = 0
    end
    if not user.patch_sign_in then
        user.patch_sign_in = 0
    end
    if not user.week_day then
        user.week_day = util.week_time(now)
    end
    if not user.contribute then
        user.contribute = 0
    end
end

function role.action(otype, info)
    action[otype].notify(info)
end

function role.action_info(otype, id)
    return action[otype].get(id)
end

function role.charge(num)
    local user = data.user
    local t
    if user.charge == 0 then
        t = base.REWARD_ACTION_FIRST_CHARGE
    else
        t = base.REWARD_ACTION_CHARGE
    end
    local r = type_reward[t][num]
    if not r then
        error{code = error_code.ERROR_CHARGE_NUM}
    end
    local p = update_user()
    role.get_reward(p, r)
    user.charge = user.charge + num
    p.user.charge = user.charge
    local vip = 0
    for k, v in ipairs(vip_level) do
        if user.charge < v.price then
            break
        else
            vip = k
        end
    end
    if vip ~= user.vip then
        for i = user.vip+1, vip do
            local l = vip_level[i]
            local m = {
                type = base.MAIL_TYPE_CHARGE,
                time = now,
                title = charge_title,
                content = string.format(charge_content, i),
                item_info = l.mailItem,
            }
            mail.add(m, p)
        end
        user.vip = vip
        p.user.vip = vip
    end
    return "update_user", {update=p}
end

function role.online_award(p, now)
    local user = data.user
    local ot, oc = user.online_award_time, user.online_award_count
    if ot > 0 then
        local c = (now - ot) // base.ONLINE_AWARD_TIME
        if c > 0 then
            oc = oc + c
            if oc >= 3 then
                oc = 3
                ot = 0
            else
                ot = ot + c * base.ONLINE_AWARD_TIME
            end
            user.online_award_time = ot
            user.online_award_count = oc
            local pu = p.user
            pu.online_award_time = ot
            pu.online_award_count = oc
            return true
        end
    end
end

function role.update_rank()
    local p = update_user()
    rank.update_arena(p)
    notify.add("update_user", {update=p})
end

function role.add_rank()
    local user = data.user
    local sl = skynet.call(rank_mgr, "lua", "get", base.RANK_SLAVE_LEVEL)
    skynet.call(sl, "lua", "add", user.id, user.level)
    local sf = skynet.call(rank_mgr, "lua", "get", base.RANK_SLAVE_FIGHT)
    skynet.call(sf, "lua", "add", user.id, user.fight_point)
    local sa = skynet.call(rank_mgr, "lua", "get", base.RANK_SLAVE_ARENA)
    skynet.call(sa, "lua", "add", user.id, user.arena_win)
    local se = skynet.call(rank_mgr, "lua", "get", base.RANK_SLAVE_EXPLORE)
    skynet.call(se, "lua", "add", user.id, user.explore_award)
    local ss = skynet.call(rank_mgr, "lua", "get", base.RANK_SLAVE_STAGE)
    skynet.call(ss, "lua", "add", user.id, data.stage_star)
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
    local now = floor(skynet.time())
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
        stage_award = {},
        trade_watch = {},
        trade_watch_count = 0,
        trade_item = {},
        exchange_count = 0,
        online_award_count = 0,
        online_award_time = now,
        arena_cd = 0,
        refresh_arena_cd = 0,
        match_count = 0,
        match_cd = 0,
        refresh_match_cd = 0,
        match_role = {},
        match_win = 0,
        mall_random = {},
        mall_count = {},
        arena_win = 0,
        explore_award = 0,
        offline_exp_time = now,
        offline_exp_count = 0,
        revive_count = 0,
        patch_sign_in = 0,
        week_day = util.week_time(now),
        contribute = 0,

        item = {},
        card = {},
        stage = {},
        task = {},
        friend = {},
        mail = {},
    }
    skynet.call(data.userdb, "lua", "save", roleid, skynet.packstring(u))
    local rank_info = {
        name = u.name,
        id = u.id,
        prof = u.prof,
        level = u.level,
        arena_rank = u.arena_rank,
        fight_point = u.fight_point,
        last_login_time = now,
        contribute = u.contribute,
        card = {},
    }
    skynet.call(data.rankinfodb, "lua", "save", roleid, skynet.packstring(rank_info))
    return "simple_user", su
end

local function enter_game(msg)
    if data.user then
        error{code = error_code.ROLE_ALREADY_ENTER}
    end
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
    local now = floor(skynet.time())
    role.repair(user, now)
    user.last_login_time = user.login_time
    user.login_time = now
    data.suser = suser
    data.user = user
    if user.level ~= suser.level then
        suser.level = user.level
    end
    local npcID = base.PROF_NPC_BASE + user.prof
    local npc = assert(npcdata[npcID], string.format("No npc data %d.", npcID))
    data.npc = npc
    data.expdata = assert(expdata[user.level], string.format("No exp data %d.", user.level))
    local pid = npc.propertyId + user.level
    data.property = assert(propertydata[pid], string.format("No property data %d.", pid))
    for k, v in ipairs(module) do
        if v.enter then
            v.enter()
        end
    end
    if user.logout_time > 0 then
        local od = game_day(user.logout_time)
        local nd = game_day(now)
        if od ~= nd then
            local owd = util.week_time(user.logout_time)
            local nwd = util.week_time(now)
            update_day(user, od, nd, owd, nwd)
        end
    end
    if user.level >= base.WEEK_TASK_LEVEL then
        task.update_week_task(user.week_day)
    end
    data.rank_info = {
        name = user.name,
        id = user.id,
        prof = user.prof,
        level = user.level,
        arena_rank = user.arena_rank,
        fight_point = user.fight_point,
        last_login_time = now,
        contribute = user.contribute,
        card = card.rank_card(),
    }
    role.init_prop()
    local p = update_user()
    if card.rank_card_full() then
        rank.add(p)
    end
    role.online_award(p, now)
    local ret = {user=user}
    local explore = skynet.call(explore_mgr, "lua", "get", user.id)
    if explore then
        data.explore = explore
        ret.explore = skynet.call(explore, "lua", "enter", user.id)
    end
    local om = skynet.call(offline_mgr, "lua", "get", user.id)
    if om then
        for k, v in ipairs(om) do
            action[v[1]].add(v[2], p)
        end
    end
    role.add_rank()
    for k, v in ipairs(module) do
        if v.pack_all then
            local key, pack = v.pack_all()
            ret[key] = pack
        end
    end
    local pack = {}
    for k, v in pairs(user.stage_award) do
        pack[#pack+1] = k
    end
    if #pack > 0 then
        ret.stage_award = pack
    end
    if user.trade_watch_count > 0 then
        local wpack = {}
        for k, v in pairs(user.trade_watch) do
            wpack[#wpack+1] = k
        end
        ret.trade_watch = wpack
    end
    if util.empty(user.mall_random) then
        update_mall_random()
    end
    local mall_random = {}
    for k, v in pairs(user.mall_random) do
        mall_random[#mall_random+1] = v
    end
    ret.mall_random = mall_random
    local mall_count = {}
    for k, v in pairs(user.mall_count) do
        mall_count[#mall_count+1] = {
            id = k,
            count = v,
        }
    end
    ret.mall_count = mall_count
    timer.add_routine("save_role", role.save_routine, 300)
    timer.add_day_routine("update_day", role.update_day)
    timer.add_second_routine("update_second", role.update_second)
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
    return "info_all", {user=ret, start_time=start_utc_time, stage_id=stageid, rand_seed=seed}
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
    local index = game_day(floor(skynet.time())) % base.MAX_SIGN_IN + 1
    assert(index<=base.MAX_SIGN_IN, string.format("Illegal sign in index %d.", index))
    local user = data.user
    local sign_in = user.sign_in
    local pindex
    local p = update_user()
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
        local l = assert(vip_level[user.vip], string.format("No vip level %d.", user.vip))
        local count = user.patch_sign_in + 1
        if count > l.freeSignUp then
            local dc = count - l.freeSignUp
            local e = assert(expdata[dc], string.format("No exp data %d.", dc))
            proc_queue(cs, function()
                if user.rmb < e.signUpPrice then
                    error{code = error_code.ROLE_RMB_LIMIT}
                end
                role.add_rmb(p, -e.signUpPrice)
            end)
        end
        user.patch_sign_in = count
        p.user.patch_sign_in = count
    else
        pindex = index
        if sign_in[pindex] then
            error{code = error_code.ALREADY_SIGN_IN}
        end
    end
    local rand_seed = floor(skynet.time())
    new_rand.init(rand_seed)
    role.sign_in(p, pindex)
    return "update_user", {update=p, sign_in=pindex, rand_seed=rand_seed}
end

function proc.explore(msg)
    if data.explore then
        error{code = error_code.ALREADY_EXPLORE}
    end
    local explore = skynet.call(explore_mgr, "lua", "get_explore", msg.area)
    if not explore then
        error{code = error_code.ERROR_EXPLORE_AREA}
    end
    -- if not card.rank_card_full() then
    --     error{code = error_code.EQUIP_CARD_LIMIT}
    -- end
    if stage.area_star(msg.area) < 15 then
        error{code = error_code.STAGE_STAR_LIMIT}
    end
    local user = data.user
    local e = skynet.call(explore, "lua", "explore", user.id, user.fight_point, user.name, user.prof, user.level)
    data.explore = explore
    return "update_user", {update={explore=e}}
end

function proc.quit_explore(msg)
    if not data.explore then
        error{code = error_code.NOT_EXPLORE}
    end
    local user = data.user
    local e = skynet.call(data.explore, "lua", "quit", user.id)
    if not e then
        error{code = error_code.ERROR_EXPLORE_STATUS}
    end
    data.explore = nil
    return "update_user", {update={explore=e}}
end

function proc.explore_fight(msg)
    if not data.explore then
        error{code = error_code.NOT_EXPLORE}
    end
    local user = data.user
    local e = skynet.call(data.explore, "lua", "fight", user.id)
    if not e then
        error{code = error_code.ERROR_EXPLORE_STATUS}
    end
    return "update_user", {update={explore=e}}
end

function proc.chat_info(msg)
    local user = data.user
    msg.id = user.id
    msg.name = user.name
    msg.level = user.level
    msg.prof = user.prof
    msg.fight_point = user.fight_point
    if msg.type == base.CHAT_TYPE_WORLD then
        skynet.send(role_mgr, "lua", "broadcast", "chat_info", msg, user.id)
        return "chat_info", msg
    elseif msg.type == base.CHAT_TYPE_PRIVATE then
        local agent = skynet.call(role_mgr, "lua", "get", msg.target)
        if agent then
            skynet.send(agent, "lua", "notify", "chat_info", msg)
            return "chat_info", msg
        else
            error{code = error_code.ROLE_OFFLINE}
        end
    else
        error{code = error_code.ERROR_CHAT_TYPE}
    end
end

function proc.get_role_info(msg)
    local info = skynet.call(role_mgr, "lua", "get_info", msg.id)
    if not info then
        error{code = error_code.ROLE_NOT_EXIST}
    end
    local pitem = {}
    local infoitem = info.item
    for k, v in pairs(infoitem) do
        if v.status == base.ITEM_STATUS_NORMAL then
            if v.pos > 0 then
                local d = assert(itemdata[v.itemid], string.format("No item data %d.", v.itemid))
                if is_equip(d.itemType) then
                    pitem[#pitem+1] = v
                elseif is_stone(d.itemType) then
                    local host = infoitem[v.host]
                    if host.pos > 0 then
                        -- NOTICE: host is equip?
                        pitem[#pitem+1] = v
                    end
                end
            end
        end
    end
    local puser = {
        user = info,
        item = pitem,
    }
    return "role_info", {info=puser}
end

function proc.exchange(msg)
    local user = data.user
    local l = assert(vip_level[user.vip], string.format("No vip level %d.", user.vip))
    if user.exchange_count >= l.golden then
        error{code = error_code.EXCHANGE_LIMIT}
    end
    local ec = user.exchange_count + 1
    local e = assert(expdata[ec], string.format("No exp data %d.", ec))
    local p = update_user()
    proc_queue(cs, function()
        if user.rmb < e.diamondToGold then
            error{code = error_code.ROLE_RMB_LIMIT}
        end
        role.add_rmb(p, -e.diamondToGold)
    end)
    role.add_money(p, 10000)
    user.exchange_count = ec
    p.user.exchange_count = ec
    return "update_user", {update=p}
end

function proc.online_award(msg)
    local user = data.user
    if user.online_award_count <= 0 then
        error{code = error_code.NO_ONLINE_AWARD}
    end
    local p = update_user()
    local pu = p.user
    user.online_award_count = user.online_award_count - 1
    pu.online_award_count = user.online_award_count
    if user.online_award_time == 0 then
        user.online_award_time = floor(skynet.time())
        pu.online_award_time = user.online_award_time
    end
    local r = assert(type_reward[base.REWARD_ACTION_ONLINE][1], "No online award.")
    role.get_reward(p, r)
    return "update_user", {update=p}
end

function proc.add_offline_exp(msg)
    local user = data.user
    local l = assert(vip_level[user.vip], string.format("No vip level %d.", user.vip))
    local count = user.offline_exp_count + 1
    local p = update_user()
    if count > l.expLimit then
        local dc = count - l.expLimit
        local e = assert(expdata[dc], string.format("No exp data %d.", dc))
        proc_queue(cs, function()
            if user.rmb < e.energyPrice then
                error{code = error_code.ROLE_RMB_LIMIT}
            end
            role.add_rmb(p, -e.energyPrice)
        end)
    end
    local now = floor(skynet.time())
    local dt = now - user.offline_exp_time
    if dt > base.OFFLINE_EXP_TIME then
        dt = base.OFFLINE_EXP_TIME
    end
    dt = dt + base.OFFLINE_EXP_TIME
    local exp = dt * base.MAX_OFFLINE_EXP // base.OFFLINE_EXP_TIME
    local pu = p.user
    user.offline_exp_time = now
    pu.offline_exp_time = now
    user.offline_exp_count = count
    pu.offline_exp_count = count
    role.add_exp(p, exp)
    return "update_user", {update=p}
end

function proc.get_offline_exp(msg)
    local user = data.user
    local now = floor(skynet.time())
    local dt = now - user.offline_exp_time
    if dt > base.OFFLINE_EXP_TIME then
        dt = base.OFFLINE_EXP_TIME
    end
    local exp = dt * base.MAX_OFFLINE_EXP // base.OFFLINE_EXP_TIME
    local p = update_user()
    local pu = p.user
    user.offline_exp_time = now
    pu.offline_exp_time = now
    role.add_exp(p, exp)
    return "update_user", {update=p}
end

return role
