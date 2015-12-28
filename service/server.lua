local skynet = require "skynet"
local queue = require "skynet.queue"

local loginservice = tonumber(...)

local userdb
local namedb
local status
local serverid
local servernam
local cs

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

function CMD.open(conf, gatename)
    cs = queue()
    serverid = conf.serverid
    servername = conf.servername
    local master = skynet.queryservice("dbmaster")
    userdb = skynet.call(master, "lua", "get", "userdb")
    namedb = skynet.call(master, "lua", "get", "namedb")
    status = skynet.call(userdb, "lua", "get", "status"..serverid)
    if status then
        status = skynet.unpack(status)
    else
        status = {
            roleid = 1,
            itemid = 1,
            cardid = 1,
        }
    end

    local server_mgr = skynet.queryservice("server_mgr")
    skynet.call(server_mgr, "lua", "register", servername, skynet.self())
    skynet.call(loginservice, "lua", "register_server", servername, gatename)
end

function CMD.shutdown()
    skynet.call(loginservice, "lua", "unregister_server", servername)
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

function CMD.gen_card()
    local cardid = status.cardid * 10000 + 3000 + serverid
    status.cardid = status.cardid + 1
    skynet.call(userdb, "lua", "save", "status", skynet.packstring(status))
    return cardid
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
