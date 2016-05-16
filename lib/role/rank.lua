local skynet = require "skynet"
local share = require "share"
local util = require "util"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local table = table
local math = math
local random = math.random

local data
local base
local error_code
local itemdata
local is_equip
local is_stone
local rank_mgr
local role_mgr
local query_process
local merge = util.merge

local card

local rank = {}
local proc = {}

local max_arena_rank = 999
local function query_arena(user_rank, count)
    local r = {}
    if user_rank <= 3 then
        local c = 4
        if c > count then
            c = count
        end
        for i = 1, c do
            r[i] = i - 1
        end
        table.remove(r, user_rank + 1)
    else
        local nr = user_rank
        if nr > max_arena_rank then
            nr = max_arena_rank
        end
        for i = 1, 3 do
            nr = (nr * (random(199) + 800)) // 1000
            r[i] = nr
        end
        table.sort(r)
    end
    return r
end

local function random_rank(user_rank, count, rank_count, dir)
    local r = {}
    if count <= rank_count then
        for i = 1, count do
            r[i] = user_rank + i * dir
        end
    else
        local mc = user_rank * rank_count // 20
        if mc < rank_count then
            mc = rank_count
        elseif mc > count then
            mc = count
        end
        local dis = mc * 1000 // rank_count
        for i = 1, rank_count do
            r[i] = user_rank + ((i - 1) * dis + random(dis)) * dir // 1000
        end
    end
    return r
end

local function query_fight_point(user_rank, count)
    local r
    local bc = count - user_rank - 1
    if user_rank == 0 then
        r = random_rank(user_rank, bc, 9, 1)
    else
        r = random_rank(user_rank, bc, 8, 1)
        merge(r, random_rank(user_rank, user_rank, 9 - #r, -1))
        table.sort(r)
    end
    return r
end

skynet.init(function()
    base = share.base
    error_code = share.error_code
    itemdata = share.itemdata
    is_equip = share.is_equip
    is_stone = share.is_stone
    rank_mgr = skynet.queryservice("rank_mgr")
    role_mgr = skynet.queryservice("role_mgr")
    query_process = {
        [base.RANK_ARENA] = query_arena,
        [base.RANK_FIGHT_POINT] = query_fight_point,
    }
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

function rank.add()
    local user = data.user
    local rank_info = {
        name = user.name,
        id = user.id,
        prof = user.prof,
        level = user.level,
        arena_rank = user.arena_rank,
        fight_point = user.fight_point,
        card = card.rank_card(),
    }
    data.rank_info = rank_info
    local arena_rank = skynet.call(rank_mgr, "lua", "add", rank_info)
    user.arena_rank = arena_rank
    rank_info.arena_rank = arena_rank
    return arena_rank
end

---------------------------protocol process----------------------

function proc.query_rank(msg)
    local process = query_process[msg.rank_type]
    if not process then
        error{code = error_code.ERROR_QUERY_RANK_TYPE}
    end
    local user_rank, count = skynet.call(rank_mgr, "lua", "get", msg.rank_type, data.user.id)
    if not user_rank then
        error{code = error_code.NOT_IN_RANK}
    end
    local r = process(user_rank, count)
    return "rank_list", {
        rank_type = msg.rank_type,
        rank = user_rank + 1,
        list = skynet.call(rank_mgr, "lua", "query", msg.rank_type, r),
    }
end

function proc.begin_challenge(msg)
    local info = skynet.call(role_mgr, "lua", "get_info", msg.id)
    if not info then
        info = skynet.call(data.userdb, "lua", "get", msg.id)
        if not info then
            error{code = error_code.ROLE_NOT_EXIST}
        end
        info = skynet.unpack(info)
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
    local puser = {
        user = info,
        item = pitem,
        card = pcard,
    }
    local stage_seed = data.stage_seed
    stage_seed.id = base.RANK_STAGE
    stage_seed.rank_type = msg.rank_type
    local bmsg = {
        id = data.user.id,
        fight = true,
    }
    skynet.send(role_mgr, "lua", "broadcast_area", "update_other", bmsg)
    return "stage_seed", {id=stage_seed.id, target=puser}
end

function proc.end_challenge(msg)
end

return rank
