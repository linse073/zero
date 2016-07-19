local skynet = require "skynet"
local share = require "share"
local util = require "util"
local notify = require "notify"
local func = require "func"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local floor = math.floor

local update_user = util.update_user
local gen_key = util.gen_key
local data
local base
local error_code
local server_mgr
local role_mgr
local offline_mgr

local friend_title
local refuse_content
local blacklist_content

local friend = {}
local proc = {}

skynet.init(function()
    base = share.base
    error_code = share.error_code
    server_mgr = skynet.queryservice("server_mgr")
    role_mgr = skynet.queryservice("role_mgr")
    offline_mgr = skynet.queryservice("offline_mgr")

    friend_title = func.get_string(198000001)
    refuse_content = func.get_string(198000002)
    blacklist_content = func.get_string(198000003)
end)

function friend.init_module()
    return proc
end

function friend.init(userdata)
    data = userdata
end

function friend.exit()
    data = nil
end

function friend.enter()
    data.friend = data.user.friend
end

function friend.pack_all()
    local pack = {}
    for k, v in pairs(data.user.friend) do
        pack[#pack+1] = v
    end
    return "friend", pack
end

function friend.add(v)
    local bm
    local nf
    local pf
    if v.status == base.FRIEND_STATUS_NEW then
        local f = data.friend[v.id]
        if f then
            if f.status == base.FRIEND_STATUS_BLACKLIST then
                bm = true
            elseif f.status == base.FRIEND_STATUS_REQUEST or f.status == base.FRIEND_STATUS_BEREQUEST then
                f.status = base.FRIEND_STATUS_NEW
                pf = v
            end
        else
            nf = true
        end
    elseif v.status == base.FRIEND_STATUS_DELETE then
        local f = data.friend[v.id]
        if f and f.status ~= base.FRIEND_STATUS_BLACKLIST then
            data.friend[v.id] = nil
            pf = v
        end
    elseif v.status == base.FRIEND_STATUS_BEREQUEST then
        local f = data.friend[v.id]
        if f then
            if f.status == base.FRIEND_STATUS_BLACKLIST then
                bm = true
            end
        else
            nf = true
        end
    end
    if bm then
        local m = {
            type = base.MAIL_TYPE_TEXT,
            time = floor(skynet.time()),
            title = friend_title,
            content = string.format(blacklist_content, data.user.name),
        }
        local agent = skynet.call(role_mgr, "lua", "get", v.id)
        if agent then
            skynet.call(agent, "lua", "action", "mail", m)
        else
            skynet.call(offline_mgr, "lua", "add", "mail", v.id, m)
        end
    end
    if nf then
        local ri = assert(skynet.call(role_mgr, "lua", "get_rank_info", v.id), string.format("No rank info %d.", v.id))
        f = {
            id = v.id,
            name = ri.name,
            prof = ri.prof,
            level = ri.level,
            fight_point = ri.fight_point,
            status = v.status,
        }
        data.friend[v.id] = f
        pf = f
    end
    return pf
end

function friend.del(id)
    data.friend[id] = nil
end

function friend.get(id)
    return data.friend[id]
end

function friend.update()
    local pf = {}
    for k, v in pairs(data.friend) do
        local ri = assert(skynet.call(role_mgr, "lua", "get_rank_info", v.id), string.format("No rank info %d.", v.id))
        local nf = {}
        if v.level ~= ri.level then
            v.level = ri.level
            nf.level = ri.level
        end
        if v.fight_point ~= ri.fight_point then
            v.fight_point = ri.fight_point
            nf.fight_point = ri.fight_point
        end
        if not util.empty(nf) then
            nf.id = v.id
            pf[#pf+1] = nf
        end
    end
    notify.add("update_user", {update={friend=pf}})
end

---------------------------protocol process----------------------

function proc.request_friend(msg)
    local f = data.friend[msg.id]
    local nf = false
    if f then
        if f.status == base.FRIEND_STATUS_NEW or f.status == base.FRIEND_STATUS_OLD then
            error{code = error_code.ALREADY_BE_FRIEND}
        elseif f.status == base.FRIEND_STATUS_REQUEST then
            error{code = error_code.ALREADY_REQUEST_FRIEND}
        elseif f.status == base.FRIEND_STATUS_BEREQUEST then
            nf = true
        end
    end
    local user = data.user
    local agent = skynet.call(role_mgr, "lua", "get", msg.id)
    if agent then
        local oi = skynet.call(agent, "lua", "action_info", "friend", user.id)
        if oi then
            if oi.status == base.FRIEND_STATUS_BLACKLIST then
                error{code = error_code.IN_BLACKLIST}
            elseif oi.status == base.FRIEND_STATUS_BEREQUEST then
                error{code = error_code.ALREADY_REQUEST_FRIEND}
            else
                nf = true
            end
        end
    end
    local p = update_user()
    local ms
    local os
    if nf then
        ms = base.FRIEND_STATUS_NEW
        os = base.FRIEND_STATUS_NEW
    else
        ms = base.FRIEND_STATUS_REQUEST
        os = base.FRIEND_STATUS_BEREQUEST
    end
    if f then
        f.status = ms
        p.friend[1] = {
            id = msg.id,
            status = ms,
        }
    else
        local ri = assert(skynet.call(role_mgr, "lua", "get_rank_info", msg.id), string.format("No rank info %d.", msg.id))
        f = {
            id = msg.id,
            name = ri.name,
            prof = ri.prof,
            level = ri.level,
            fight_point = ri.fight_point,
            status = ms,
        }
        data.friend[msg.id] = f
        p.friend[1] = f
    end
    local info = {
        id = user.id,
        status = os,
    }
    if agent then
        skynet.call(agent, "lua", "action", "friend", info)
    else
        skynet.call(offline_mgr, "lua", "add", "friend", msg.id, info)
    end
    return "update_user", {update=p}
end

function proc.confirm_friend(msg)
    local f = data.friend[msg.id]
    if not f then
        error{code = error_code.NO_FRIEND_REQUEST}
    end
    if f.status ~= base.FRIEND_STATUS_BEREQUEST then
        error{code = error_code.ERROR_FRIEND_STATUS}
    end
    local user = data.user
    if msg.accept then
        local agent = skynet.call(role_mgr, "lua", "get", msg.id)
        if agent then
            local oi = skynet.call(agent, "lua", "action_info", "friend", user.id)
            if oi then
                if oi.status == base.FRIEND_STATUS_BLACKLIST then
                    error{code = error_code.IN_BLACKLIST}
                end
            end
        end
        local info = {
            id = user.id,
            status = base.FRIEND_STATUS_NEW,
        }
        if agent then
            skynet.call(agent, "lua", "action", "friend", info)
        else
            skynet.call(offline_mgr, "lua", "add", "friend", msg.id, info)
        end
        f.status = base.FRIEND_STATUS_NEW
        local p = update_user()
        p.friend[1] = {
            id = msg.id,
            status = f.status,
        }
        return "update_user", {update=p}
    else
        local m = {
            type = base.MAIL_TYPE_TEXT,
            time = floor(skynet.time()),
            title = friend_title,
            content = string.format(refuse_content, user.name),
        }
        local info = {
            id = user.id,
            status = base.FRIEND_STATUS_DELETE,
        }
        local agent = skynet.call(role_mgr, "lua", "get", msg.id)
        if agent then
            skynet.call(agent, "lua", "action", "mail", m)
            skynet.call(agent, "lua", "action", "friend", info)
        else
            skynet.call(offline_mgr, "lua", "add", "mail", msg.id, m)
            skynet.call(offline_mgr, "lua", "add", "friend", msg.id, info)
        end
        friend.del(msg.id)
        local p = update_user()
        p.friend[1] = {
            id = msg.id,
            status = base.FRIEND_STATUS_DELETE,
        }
        return "update_user", {update=p}
    end
end

function proc.blacklist(msg)
    local f = data.friend[msg.id]
    local p = update_user()
    if f then
        if f.status == base.FRIEND_STATUS_BLACKLIST then
            error{code = error_code.ALREADY_IN_BLACKLIST}
        else
            f.status = base.FRIEND_STATUS_BLACKLIST
            p.friend[1] = {
                id = msg.id,
                status = f.status,
            }
        end
    else
        local ri = assert(skynet.call(role_mgr, "lua", "get_rank_info", msg.id), string.format("No rank info %d.", msg.id))
        f = {
            id = msg.id,
            name = ri.name,
            prof = ri.prof,
            level = ri.level,
            fight_point = ri.fight_point,
            status = base.FRIEND_STATUS_BLACKLIST,
        }
        data.friend[msg.id] = f
        p.friend[1] = f
    end
    local user = data.user
    local info = {
        id = user.id,
        status = base.FRIEND_STATUS_DELETE,
    }
    local agent = skynet.call(role_mgr, "lua", "get", msg.id)
    if agent then
        skynet.call(agent, "lua", "action", "friend", info)
    else
        skynet.call(offline_mgr, "lua", "add", "friend", msg.id, info)
    end
    return "update_user", {update=p}
end

function proc.del_friend(msg)
    local f = data.friend[msg.id]
    if not f then
        error{code = error_code.FRIEND_NOT_EXIST}
    end
    friend.del(msg.id)
    local p = update_user()
    p.friend[1] = {
        id = msg.id,
        status = base.FRIEND_STATUS_DELETE,
    }
    local user = data.user
    local info = {
        id = user.id,
        status = base.FRIEND_STATUS_DELETE,
    }
    local agent = skynet.call(role_mgr, "lua", "get", msg.id)
    if agent then
        skynet.call(agent, "lua", "action", "friend", info)
    else
        skynet.call(offline_mgr, "lua", "add", "friend", msg.id, info)
    end
    return "update_user", {update=p}
end

function proc.old_friend(msg)
    for k, v in pairs(data.friend) do
        if v.status == base.FRIEND_STATUS_NEW then
            v.status = base.FRIEND_STATUS_OLD
        end
    end
    return "old_friend", ""
end

function proc.query_friend(msg)
    if not msg.name then
        error{code = error_code.ERROR_FRIEND_NAME}
    end
    local info = {}
    local server_list = skynet.call(server_mgr, "lua", "get_all")
    for k, v in pairs(server_list) do
        local namekey = gen_key(k, msg.name)
        local roleid = skynet.call(data.namedb, "lua", "get", namekey)
        -- TODO: roleid is string or float?
        if roleid then
            local ri = assert(skynet.call(role_mgr, "lua", "get_rank_info", roleid), string.format("No rank info %d.", roleid))
            info[#info+1] = ri
        end
    end
    return "query_friend_info", {info=info}
end

return friend
