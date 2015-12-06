local skynet = require "skynet"
local queue = require "skynet.queue"

local userdb
local namedb
local status
local serverid
local cs
local gate_list = {}

local CMD = {}

local function check_name(name)
    if skynet.call(namedb, "lua", "has", name) then
        return 0
    else
        local roleid = status.roleid * 10000 + 1000 + serverid
        status.roleid = status.roleid + 1
        skynet.call(namedb, "lua", "save", name, roleid)
        return roleid
    end
end

function CMD.open(conf, loginserver)
    for k, v in ipairs(conf.gate) do
        local gate = skynet.newservice("gate", loginserver)
        skynet.call(gate, "lua", "open", v, conf.servername)
        gate_list[#gate_list+1] = gate
    end
    for k, v in ipairs(conf.db) do
        local db = skynet.newservice("dbslave")
        skynet.call(db, "lua", "open", v, conf.servername)
    end
    
    cs = queue()
    local master = skynet.queryservice("dbmaster")
    userdb = skynet.call(master, "lua", "get", conf.servername, "userdb")
    namedb = skynet.call(master, "lua", "get", conf.servername, "namedb")
    status = skynet.call(userdb, "lua", "get", "status")
    if status then
        status = skynet.unpack(status)
    else
        status = {
            roleid = 1,
            itemid = 1,
        }
    end

    serverid = conf.serverid
    local server_mgr = skynet.queryservice("server_mgr")
    skynet.call(server_mgr, "lua", "register", conf.servername, skynet.self())
end

function CMD.shutdown()
    for k, v in ipairs(gate_list) do
        skynet.call(v, "lua", "close")
        pcall(skynet.call, v, "lua", "shutdown")
    end
end

function CMD.gen_role(name)
    local roleid = cs(check_name, name)
    if roleid ~= 0 then
        skynet.call(userdb, "lua", "save", "status", skynet.packstring(status))
    end
    return roleid
end

function CMD.gen_item()
    local itemid = status.itemid * 10000 + 2000 + serverid
    status.itemid = status.itemid + 1
    skynet.call(userdb, "lua", "save", "status", skynet.packstring(status))
    return itemid
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
