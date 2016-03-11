local skynet = require "skynet"
local share = require "share"

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

local rank = {}
local proc = {}

local function query_arena()
    local rank, count = skynet.call(rank_mgr, "lua", "get", base.RANK_ARENA, data.user.id)
    local r = {}
    if rank <= 3 then
        local c = 4
        if c > count then
            c = count
        end
        for i = 1, c do
            r[i] = i - 1
        end
        table.remove(r, rank + 1)
    else
        local nr = rank
        for i = 1, 3 do
            nr = (nr * (random(199) + 800)) // 1000
            r[i] = nr
        end
        table.sort(r)
    end
    return {
        rank_type = base.RANK_ARENA,
        rank = rank + 1,
        list = skynet.call(rank_mgr, "lua", "query", base.RANK_ARENA, r),
    }
end

local function query_fight_point()
    local rank = skynet.call(rank_mgr, "lua", "get", base.RANK_FIGHT_POINT, data.user.id)
    local r = {}
    if rank > 0 then
        r[1] = (rank * (random(49) + 950)) // 1000
    end
    -- TODO: other rank info
    return {
        rank_type = base.RANK_ARENA,
        rank = rank + 1,
        list = skynet.call(rank_mgr, "lua", "query", base.RANK_FIGHT_POINT, r),
    }
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
    return proc
end

function rank.init(userdata)
    data = userdata
end

function rank.exit()
    data = nil
end

---------------------------protocol process----------------------

function proc.query_rank(msg)
    local process = query_process[msg.rank_type]
    if not process then
        error{code = error_code.ERROR_QUERY_RANK_TYPE}
    end
    return "rank_list", process()
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
        if v.pos[2] > 0 then
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
