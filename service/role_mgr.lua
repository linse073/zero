local skynet = require "skynet"
local sharedata = require "sharedata"
local sprotoloader = require "sprotoloader"

local assert = assert
local string = string
local ipairs = ipairs
local pairs = pairs

local MAX_AREA_ROLE = 100

local role_list = {}
local area_list = {}
local sproto
local name_msg

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
        area = {num = 0}
        area_list[#area_list+1] = area
    end
    return area
end

function notify_area(roleid, agent, area)
    local pack = {}
    for k, v in pairs(area) do
        if k ~= roleid then
            pack[#pack+1] = v[3]
        end
    end
    skyent.send(agent, "lua", "notify", "other_all", {other=pack})
end

function CMD.enter(info, agent)
    local roleid = info.id
    assert(not role_list[roleid], string.format("Role already enter %d.", roleid))
    local area = gen_area()
    area[roleid] = agent
    area.num = area.num + 1
    role_list[roleid] = {agent, area, info}
    CMD.broadcast_area("other_info", info)
    notify_area(roleid, agent, area)
end

function CMD.logout(roleid)
    CMD.broadcast_area("logout", {id=roleid})
    local role = assert(role_list[roleid], string.format("No role %d.", roleid))
    local area = role[2]
    area[roleid] = nil
    area.num = area.num - 1
    role_list[roleid] = nil
end

function CMD.get(roleid)
    local role = assert(role_list[roleid], string.format("No role %d.", roleid))
    return role[1]
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

function CMD.broadcast_area(msg, info)
    local id = info.id
    local role = assert(role_list[id], string.format("No role %d.", id))
    local area = role[2]
    local c = pack_msg(msg, info)
    for k, v in pairs(area) do
        if k ~= id then
            skynet.send(v, "lua", "notify", c)
        end
    end
    if msg == "other_info" then
        local oi = role[3]
        for k, v in pairs(info) do
            oi[k] = v
        end
    end
end

skynet.start(function()
    sproto = sprotoloader.load(1)
    name_msg = sharedata.query("name_msg")

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            f(...)
        else
            skynet.retpack(f(...))
        end
	end)
end)
