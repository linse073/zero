local skynet = require "skynet"
local queue = require "skynet.queue"
local util = require "util"

local loginservice = tonumber(...)

local assert = assert

local gen_key = util.gen_key
local cs = queue()
local statusdb
local namedb
local status_key
local status
local config

local CMD = {}

local function check_name(name)
    local namekey = gen_key(config.serverid, name)
    if skynet.call(namedb, "lua", "has", namekey) then
        return 0
    else
        local roleid = status.roleid * 10000 + 1000 + config.serverid
        status.roleid = status.roleid + 1
        skynet.call(namedb, "lua", "save", namekey, roleid)
        return roleid
    end
end

function CMD.open(conf, gatename)
    config = conf
    local master = skynet.queryservice("dbmaster")
    statusdb = skynet.call(master, "lua", "get", "statusdb")
    namedb = skynet.call(master, "lua", "get", "namedb")
    status_key = gen_key(config.serverid, "status")
    status = skynet.call(statusdb, "lua", "get", status_key)
    if not status then
        local userdb = skynet.call(master, "lua", "get", "userdb")
        status = skynet.call(userdb, "lua", "get", status_key)
        if status then
            skynet.call(userdb, "lua", "del", status_key)
            skynet.call(statusdb, "lua", "save", status_key, status)
        end
    end
    if status then
        status = skynet.unpack(status)
        if not status.mailid then
            status.mailid = 1
        end
    else
        status = {
            roleid = 1,
            itemid = 1,
            cardid = 1,
            mailid = 1,
        }
    end

    local server_mgr = skynet.queryservice("server_mgr")
    skynet.call(server_mgr, "lua", "register", config.serverid, skynet.self())
    skynet.call(loginservice, "lua", "register_server", conf, gatename)
end

function CMD.shutdown()
    skynet.call(loginservice, "lua", "unregister_server", config.servername)
end

function CMD.gen_role(name)
    local roleid = cs(check_name, name)
    if roleid > 0 then
        skynet.call(statusdb, "lua", "save", status_key, skynet.packstring(status))
    end
    return roleid
end

function CMD.gen_item()
    local itemid = status.itemid * 10000 + 2000 + config.serverid
    status.itemid = status.itemid + 1
    skynet.call(statusdb, "lua", "save", status_key, skynet.packstring(status))
    return itemid
end

function CMD.gen_card()
    local cardid = status.cardid * 10000 + 3000 + config.serverid
    status.cardid = status.cardid + 1
    skynet.call(statusdb, "lua", "save", status_key, skynet.packstring(status))
    return cardid
end

function CMD.gen_mail()
    local mailid = status.mailid * 10000 + 4000 + config.serverid
    status.mailid = status.mailid + 1
    skynet.call(statusdb, "lua", "save", status_key, skynet.packstring(status))
    return mailid
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
