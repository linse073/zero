local skynet = require "skynet"
local share = require "share"
local func = require "func"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string

local card
local data
local base
local error_code
local itemdata
local is_equip
local is_stone
local arena_rank
local fight_point_rank
local role_mgr
local query_process

local rank = {}
local proc = {}

skynet.init(function()
    base = share.base
    error_code = share.error_code
    itemdata = share.itemdata
    is_equip = func.is_equip
    is_stone = func.is_stone
    arena_rank = skynet.queryservice("arena_rank")
    fight_point_rank = skynet.queryservice("fight_point_rank")
    role_mgr = skynet.queryservice("role_mgr")
    query_process = {
        [base.RANK_ARENA] = arena_rank,
        [base.RANK_FIGHT_POINT] = fight_point_rank,
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
    local info = data.rank_info
    local arena_rank = skynet.call(arena_rank, "lua", "add", info.id)
    skynet.call(fight_point_rank, "lua", "add", info.id, info.fight_point)
    user.arena_rank = arena_rank
    info.arena_rank = arena_rank
    return arena_rank
end

---------------------------protocol process----------------------

function proc.query_rank(msg)
    local process = query_process[msg.rank_type]
    if not process then
        error{code = error_code.ERROR_QUERY_RANK_TYPE}
    end
    local user = data.user
    local user_rank, list = skynet.call(process, "lua", "query", user.id)
    if not user_rank then
        error{code = error_code.NOT_IN_RANK}
    end
    for k, v in ipairs(list) do
        local info = skynet.call(role_mgr, "lua", "get_rank_info", v)
        info.rank = r[k] + 1
        list[k] = info
    end
    return "rank_list", {
        rank_type = msg.rank_type,
        rank = user_rank + 1,
        list = list,
    }
end

function proc.begin_challenge(msg)
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
