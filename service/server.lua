local skynet = require "skynet"
local queue = require "skynet.queue"
local util = require "util"

local loginservice = tonumber(...)

local assert = assert

local gen_key = util.gen_key
local gen_account = util.gen_account
local cs = queue()
local statusdb
local namedb
local accountnamedb
local status_key
local status
local config

local CMD = {}

local function check_account(info)
    local namekey = gen_account(info.loginType, config.serverid, info.uid)
    local account = skynet.call(accountnamedb, "lua", "get", namekey)
    if account then
        if info.register then
            return false, nil, "name exist"
        else
            account = skynet.unpack(account)
            if info.password then
                if info.password == account.password then
                    return false, account
                else
                    return false, nil, "password error"
                end
            else
                return false, account
            end
        end
    else
        local accountid = status.accountid * 10000 + 6000 + config.serverid
        status.accountid = status.accountid + 1
        local account = {
            id = accountid,
            password = info.password,
        }
        skynet.call(accountnamedb, "lua", "set", namekey, skynet.packstring(account))
        return true, account
    end
end

local function check_name(name)
    local namekey = gen_key(config.serverid, name)
    if skynet.call(namedb, "lua", "exists", namekey) then
        return 0
    else
        local roleid = status.roleid * 10000 + 1000 + config.serverid
        status.roleid = status.roleid + 1
        skynet.call(namedb, "lua", "set", namekey, roleid)
        return roleid
    end
end

function CMD.open(conf, gatename)
    config = conf
    local master = skynet.queryservice("dbmaster")
    statusdb = skynet.call(master, "lua", "get", "statusdb")
    namedb = skynet.call(master, "lua", "get", "namedb")
    accountnamedb = skynet.call(master, "lua", "get", "accountnamedb")
    status_key = gen_key(config.serverid, "status")
    status = skynet.call(statusdb, "lua", "get", status_key)
    if not status then
        local userdb = skynet.call(master, "lua", "get", "userdb")
        status = skynet.call(userdb, "lua", "get", status_key)
        if status then
            skynet.call(userdb, "lua", "del", status_key)
            skynet.call(statusdb, "lua", "set", status_key, status)
        end
    end
    if status then
        status = skynet.unpack(status)
        if not status.mailid then
            status.mailid = 1
        end
        if not status.guildid then
            status.guildid = 1
        end
        if not status.accountid then
            status.accountid = 1
        end
    else
        status = {
            accountid = 1,
            roleid = 1,
            itemid = 1,
            cardid = 1,
            mailid = 1,
            guildid = 1,
        }
    end

    local server_mgr = skynet.queryservice("server_mgr")
    skynet.call(server_mgr, "lua", "register", config.serverid, skynet.self())
    skynet.call(loginservice, "lua", "register_server", conf, gatename, skynet.self())
end

function CMD.shutdown()
    skynet.call(loginservice, "lua", "unregister_server", config.servername)
end

function CMD.gen_account(info)
    local new, account, errmsg = cs(check_account, info)
    if new then
        skynet.call(statusdb, "lua", "set", status_key, skynet.packstring(status))
    end
    return new, account, errmsg
end

function CMD.gen_role(name)
    local roleid = cs(check_name, name)
    if roleid > 0 then
        skynet.call(statusdb, "lua", "set", status_key, skynet.packstring(status))
    end
    return roleid
end

function CMD.gen_item()
    local itemid = status.itemid * 10000 + 2000 + config.serverid
    status.itemid = status.itemid + 1
    skynet.call(statusdb, "lua", "set", status_key, skynet.packstring(status))
    return itemid
end

function CMD.gen_card()
    local cardid = status.cardid * 10000 + 3000 + config.serverid
    status.cardid = status.cardid + 1
    skynet.call(statusdb, "lua", "set", status_key, skynet.packstring(status))
    return cardid
end

function CMD.gen_mail()
    local mailid = status.mailid * 10000 + 4000 + config.serverid
    status.mailid = status.mailid + 1
    skynet.call(statusdb, "lua", "set", status_key, skynet.packstring(status))
    return mailid
end

function CMD.gen_guild()
    local guildid = status.guildid * 10000 + 5000 + config.serverid
    status.guildid = status.guildid + 1
    skynet.call(statusdb, "lua", "set", status_key, skynet.packstring(status))
    return guildid
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
