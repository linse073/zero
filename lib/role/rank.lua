local skynet = require "skynet"
local share = require "share"
local func = require "func"
local util = require "util"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local floor = math.floor

local check_sign = util.check_sign
local update_user = util.update_user
local card
local data
local base
local error_code
local itemdata
local type_reward
local is_equip
local is_stone
local arena_rank
local fight_point_rank
local role_mgr
local query_process

local match_title
local match_content

local rank = {}
local proc = {}

skynet.init(function()
    base = share.base
    error_code = share.error_code
    itemdata = share.itemdata
    type_reward = share.type_reward
    is_equip = func.is_equip
    is_stone = func.is_stone
    arena_rank = skynet.queryservice("arena_rank")
    fight_point_rank = skynet.queryservice("fight_point_rank")
    role_mgr = skynet.queryservice("role_mgr")
    query_process = {
        [base.RANK_ARENA] = arena_rank,
        [base.RANK_FIGHT_POINT] = fight_point_rank,
    }

    match_title = func.get_string(198000009)
    match_content = func.get_string(198000010)
end)

function rank.init_module()
    card = require "role.card"
    return proc
end

function rank.init(userdata)
    data = userdata
end

function rank.exit()
    data = nil
end

function rank.add(p)
    local user = data.user
    local info = data.rank_info
    local arena_rank = skynet.call(arena_rank, "lua", "add", info.id)
    skynet.call(fight_point_rank, "lua", "add", info.id, info.fight_point)
    user.arena_rank = arena_rank
    info.arena_rank = arena_rank
    local pu = p.user
    pu.arena_rank = arena_rank
    local now = floor(skynet.time())
    if user.arena_cd == 0 then
        user.arena_cd = now - base.ARENA_CHALLENGE_TIME
        pu.arena_cd = user.arena_cd
    end
    if user.match_cd == 0 then
        user.match_cd = now
        pu.match_cd = now
    end
    if util.empty(user.match_role) then
        local match_role = {}
        local fight_rank, list = skynet.call(fight_point_rank, "lua", "query", user.id)
        for k, v in ipairs(list) do
            match_role[v] = false
        end
        user.match_role = match_role
    end
end

function rank.update_day()
    -- TODO: arena award
end

---------------------------protocol process----------------------

function proc.query_rank(msg)
    if msg.rank_type == base.RANK_FIGHT_POINT then
        local user = data.user
        local now = floor(skynet.time())
        local dt = now - user.match_cd
        if dt >= base.MATCH_REFLESH_TIME then
            local user_rank, list = skynet.call(fight_point_rank, "lua", "query", user.id)
            if not user_rank then
                error{code = error_code.NOT_IN_RANK}
            end
            local l = {}
            local match_role = {}
            for k, v in ipairs(list) do
                local id = v[1]
                local info = skynet.call(role_mgr, "lua", "get_rank_info", id)
                info.rank = v[2] + 1
                info.win = false
                l[k] = info
                match_role[id] = false
            end
            user.match_role = match_role
            user.match_cd = user.match_cd + dt // base.MATCH_REFLESH_TIME * base.MATCH_REFLESH_TIME
            return "rank_list", {
                rank_type = msg.rank_type,
                rank = user_rank + 1,
                list = l,
                cd = user.match_cd,
            }
        else
            local match_role = user.match_role
            local r = {user.id}
            for k, v in pairs(match_role) do
                r[#r+1] = k
            end
            if #r == 1 then
                error{code = error_code.NOT_IN_RANK}
            end
            local cr = skynet.call(fight_point_rank, "lua", "batch_get", r)
            local l = {}
            for k, v in pairs(match_role) do
                local info = skynet.call(role_mgr, "lua", "get_rank_info", k)
                info.rank = cr[k] + 1
                info.win = v
                l[#l+1] = info
            end
            return "rank_list", {
                rank_type = msg.rank_type,
                rank = cr[user.id] + 1,
                list = l,
            }
        end
    else
        local process = query_process[msg.rank_type]
        if not process then
            error{code = error_code.ERROR_QUERY_RANK_TYPE}
        end
        local user = data.user
        local user_rank, list = skynet.call(process, "lua", "query", user.id)
        if not user_rank then
            error{code = error_code.NOT_IN_RANK}
        end
        local l = {}
        for k, v in ipairs(list) do
            local id = v[1]
            local info = skynet.call(role_mgr, "lua", "get_rank_info", id)
            info.rank = v[2] + 1
            l[k] = info
        end
        return "rank_list", {
            rank_type = msg.rank_type,
            rank = user_rank + 1,
            list = l,
        }
    end
end

function proc.begin_challenge(msg)
    local info = skynet.call(role_mgr, "lua", "get_info", msg.id)
    if not info then
        error{code = error_code.ROLE_NOT_EXIST}
    end
    local user = data.user
    local u = {
        id = base.RANK_STAGE,
        rank_type = msg.rank_type,
    }
    if msg.rank_type == base.RANK_ARENA then
        if user.arena_count >= base.MAX_ARENA_COUNT then
            error{code = error_code.ARENA_COUNT_LIMIT}
        end
        local now = floor(skynet.time())
        if now - user.arena_cd < base.ARENA_CHALLENGE_TIME then
            error{code = error_code.CHALLENGE_TIME_LIMIT}
        end
        user.arena_cd = now
        u.cd = now
        user.arena_count = user.arena_count + 1
        u.count = user.arena_count
    elseif msg.rank_type == base.RANK_FIGHT_POINT then
        if user.match_count >= base.MAX_MATCH_COUNT then
            error{code = error_code.MATCH_COUNT_LIMIT}
        end
        if user.match_role[msg.id] then
            error{code = error_code.ALREADY_WIN_MATCH}
        end
        user.match_count = user.match_count + 1
        u.count = user.match_count
    else
        error{code = error_code.ERROR_QUERY_RANK_TYPE}
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
    local pcard = {}
    local infocard = info.card
    for k, v in pairs(infocard) do
        if v.pos[1] > 0 then
            pcard[#pcard+1] = v
        end
    end
    u.target = {
        user = info,
        item = pitem,
        card = pcard,
    }
    local stage_seed = data.stage_seed
    stage_seed.id = base.RANK_STAGE
    stage_seed.rank_type = msg.rank_type
    stage_seed.target = msg.id
    local bmsg = {
        id = user.id,
        fight = true,
    }
    skynet.send(role_mgr, "lua", "broadcast_area", "update_other", bmsg)
    return "stage_seed", u
end

function proc.end_challenge(msg)
    local stage_seed = data.stage_seed
    if stage_seed.target ~= msg.id then
        error{code = error_code.ERROR_CHALLENGE_TARGET}
    end
    if not check_sign(msg, data.secret) then
        error{code = error_code.ERROR_SIGN}
    end
    if msg.rank_type == base.RANK_ARENA then
        local user = data.user
        local r1 = skynet.call(arena_rank, "lua", "update", user.id, msg.id)
        local p = update_user()
        if r1 then
            user.arena_rank = r1 + 1
            p.user.arena_rank = user.arena_rank
            local agent = skynet.call(role_mgr, "lua", "get", msg.id)
            if agent then
                skynet.call(agent, "lua", "update_rank")
            end
        end
        return "update_user", {update=p}
    elseif msg.rank_type == base.RANK_FIGHT_POINT then
        local user = data.user
        local p = update_user()
        user.match_win = user.match_win + 1
        p.user.match_win = user.match_win
        user.match_role[msg.id] = true
        local rw = type_reward[base.REWARD_ACTION_ARENA][user.match_win]
        if rw then
            local m = {
                type = base.MAIL_TYPE_ARENA,
                time = now,
                title = match_title,
                content = string.format(match_content, user.match_win),
            }
            if rw.rewardType == base.REWARD_TYPE_ITEM then
                m.item_info = {
                    {itemid=rw.reward, num=rw.rewardNum},
                }
            elseif rw.rewardType == base.REWARD_TYPE_RMB then
                m.item_info = {
                    {itemid=base.RMB_ITEM, num=rw.reward},
                }
            end
            mail.add(m)
            p.mail[1] = m
        end
        return "update_user", {update=p}
    else
        error{code = error_code.ERROR_QUERY_RANK_TYPE}
    end
end

function proc.reflesh_arena(msg)
    if msg.rank_type == base.RANK_ARENA then
        local user = data.user
        if user.arena_rank == 0 then
            error{code = error_code.NOT_IN_RANK}
        end
        local now = floor(skynet.time())
        if now - user.arena_cd >= base.ARENA_CHALLENGE_TIME then
            error{code = error_code.CHALLENGE_NOT_CD}
        end
        -- TODO: rmb
        local p = update_user()
        local pu = p.user
        user.arena_cd = now - base.ARENA_CHALLENGE_TIME
        pu.arena_cd = user.arena_cd
        user.reflesh_arena_cd = user.reflesh_arena_cd + 1
        pu.reflesh_arena_cd = user.reflesh_arena_cd
        return "update_user", {update=p}
    elseif msg.rank_type == base.RANK_FIGHT_POINT then
        local user = data.user
        local user_rank, list = skynet.call(fight_point_rank, "lua", "query", user.id)
        if not user_rank then
            error{code = error_code.NOT_IN_RANK}
        end
        -- TODO: rmb
        local p = update_user()
        local pu = p.user
        user.reflesh_match_cd = user.reflesh_match_cd + 1
        pu.reflesh_match_cd = user.reflesh_match_cd
        local l = {}
        local match_role = {}
        for k, v in ipairs(list) do
            local info = skynet.call(role_mgr, "lua", "get_rank_info", v)
            info.rank = list[k] + 1
            info.win = false
            l[k] = info
            match_role[v] = false
        end
        user.match_role = match_role
        local now = floor(skynet.time())
        user.match_cd = now
        pu.match_cd = now
        user.match_count = 0
        pu.match_count = 0
        user.match_win = 0
        pu.match_win = 0
        return "update_user", {update=p, rank_list={
            rank_type = msg.rank_type,
            rank = user_rank + 1,
            list = l,
        }}
    else
        error{code = error_code.ERROR_QUERY_RANK_TYPE}
    end
end

return rank
