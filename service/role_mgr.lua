local skynet = require "skynet"
local sharedata = require "sharedata"
local sprotoloader = require "sprotoloader"

local assert = assert
local string = string
local ipairs = ipairs
local pairs = pairs
local type = type

local MAX_AREA_ROLE = 100

local role_list = {}
local area_list = {}
local sproto
local name_msg
local userdb
local rankinfodb

local CMD = {}

local function gen_area()
    local area, area_num
    for k, v in ipairs(area_list) do
        local num = v.num
        if not area or (num > area_num and num < MAX_AREA_ROLE) then
            area = v
            area_num = num
        end
    end
    if not area then
        area = {num=0, role={}}
        area_list[#area_list+1] = area
    end
    return area
end

function notify_area(roleid, agent, area)
    local pack = {}
    for k, v in pairs(area.role) do
        if k ~= roleid then
            pack[#pack+1] = v[2]
        end
    end
    skynet.send(agent, "lua", "notify", "other_all", {other=pack})
end

function CMD.enter(info, agent)
    local roleid = info.id
    assert(not role_list[roleid], string.format("Role already enter %d.", roleid))
    local area = gen_area()
    area.role[roleid] = {agent, info}
    area.num = area.num + 1
    role_list[roleid] = {agent, area}
    CMD.broadcast_area("other_info", info)
    notify_area(roleid, agent, area)
    skynet.error(string.format("Role enter %d.", roleid))
end

function CMD.logout(roleid)
    local role = role_list[roleid]
    if role then
        CMD.broadcast_area("logout", {id=roleid})
        local area = role[2]
        area.role[roleid] = nil
        area.num = area.num - 1
        role_list[roleid] = nil
        skynet.error(string.format("Role logout %d.", roleid))
    end
end

function CMD.get(roleid)
    local role = role_list[roleid]
    if role then
        return role[1]
    end
end

function CMD.online(roleid)
    return role_list[roleid] ~= nil
end

local function pack_msg(msg, info)
    if sproto:exist_type(msg) then
        info = sproto:pencode(msg, info)
    end
    local id = assert(name_msg[msg], string.format("No protocol %s.", msg))
    return string.pack(">s2", string.pack(">I2", id) .. info)
end

function CMD.broadcast(msg, info, exclude)
    local c = pack_msg(msg, info)
    for k, v in pairs(role_list) do
        if k ~= exclude then
            skynet.send(v[1], "lua", "notify", c)
        end
    end
end

function CMD.broadcast_range(msg, info, range)
    local c = pack_msg(msg, info)
    for k, v in ipairs(range) do
        local role = role_list[v]
        if role then
            skynet.send(role[1], "lua", "notify", c)
        end
    end
end

function CMD.broadcast_area(msg, info)
    local id = info.id
    local role = assert(role_list[id], string.format("No role %d.", id))
    local area = role[2]
    local c = pack_msg(msg, info)
    for k, v in pairs(area.role) do
        if k ~= id then
            skynet.send(v[1], "lua", "notify", c)
        else
            if msg == "update_other" then
                local oi = v[2]
                for k1, v1 in pairs(info) do
                    oi[k1] = v1
                end
                local des_pos = info.des_pos
                if des_pos then
                    oi.cur_pos.x = des_pos.x
                    oi.cur_pos.y = des_pos.y
                end
            end
        end
    end
end

function CMD.get_info(roleid)
    local t = type(roleid)
    assert(t=="number", string.format("Error argument type %s.", t))
    local role = role_list[roleid]
    if role then
        return skynet.call(role[1], "lua", "get_info"), true
    else
        local info = skynet.call(userdb, "lua", "get", roleid)
        if info then
            return skynet.unpack(info), false
        else
            skynet.error(string.format("No role info %d.", roleid))
        end
    end
end

function CMD.get_rank_info(roleid)
    local t = type(roleid)
    assert(t=="number", string.format("Error argument type %s.", t))
    local role = role_list[roleid]
    if role then
        return skynet.call(role[1], "lua", "get_rank_info"), true
    else
        local info = skynet.call(rankinfodb, "lua", "get", roleid)
        if info then
            return skynet.unpack(info), false
        else
            skynet.error(string.format("No role rank info %d.", roleid))
        end
    end
end

skynet.start(function()
    sproto = sprotoloader.load(1)
    name_msg = sharedata.query("name_msg")
    local master = skynet.queryservice("dbmaster")
    userdb = skynet.call(master, "lua", "get", "userdb")
    rankinfodb = skynet.call(master, "lua", "get", "rankinfodb")

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            f(...)
        else
            skynet.retpack(f(...))
        end
	end)
end)
