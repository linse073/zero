local skynet = require "skynet"
local queue = require "skynet.queue"
local util = require "util"

local loginservice = tonumber(...)

local gen_key = util.gen_key
local cs = queue()
local userdb
local namedb
local status_key
local status
local serverid
local servernam

local CMD = {}

local function check_name(name)
    local namekey = gen_key(serverid, name)
    if skynet.call(namedb, "lua", "has", namekey) then
        return 0
    else
        local roleid = status.roleid * 10000 + 1000 + serverid
        status.roleid = status.roleid + 1
        skynet.call(namedb, "lua", "save", namekey, roleid)
        return roleid
    end
end

function CMD.open(conf, gatename)
    serverid = conf.serverid
    servername = conf.servername
    local master = skynet.queryservice("dbmaster")
    userdb = skynet.call(master, "lua", "get", "userdb")
    namedb = skynet.call(master, "lua", "get", "namedb")
    status_key = gen_key(serverid, "status")
    status = skynet.call(userdb, "lua", "get", status_key)
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
    skynet.call(server_mgr, "lua", "register", serverid, skynet.self())
    skynet.call(loginservice, "lua", "register_server", conf, gatename)
end

function CMD.shutdown()
    skynet.call(loginservice, "lua", "unregister_server", servername)
end

function CMD.gen_role(name)
    local roleid = cs(check_name, name)
    if roleid > 0 then
        skynet.call(userdb, "lua", "save", status_key, skynet.packstring(status))
    end
    return roleid
end

function CMD.gen_item()
    local itemid = status.itemid * 10000 + 2000 + serverid
    status.itemid = status.itemid + 1
    skynet.call(userdb, "lua", "save", status_key, skynet.packstring(status))
    return itemid
end

function CMD.gen_card()
    local cardid = status.cardid * 10000 + 3000 + serverid
    status.cardid = status.cardid + 1
    skynet.call(userdb, "lua", "save", status_key, skynet.packstring(status))
    return cardid
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
