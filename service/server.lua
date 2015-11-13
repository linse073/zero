local snax = require "snax"
local queue = require "skynet.queue"

local userdb
local namedb
local status
local serverid
local cs

function init(conf)
    cs = queue()
    serverid = conf.serverid
    local master = snax.queryservice("dbmaster")
    userdb = snax.bind(master.req.get_slave("userdb"))
    namedb = snax.bind(master.req.get_slave("namedb"))
    status = userdb.req.get("status")
    if status then
        status = skynet.unpack(status)
    else
        status = {
            roleid = 1,
            itemid = 1,
        }
    end
    local server_mgr = snax.queryservice("server_mgr")
    server_mgr.req.register_server(conf, skynet.self(), SERVER_NAME)
end

function exit()
    
end

local function check_name(name)
    if namedb.req.has(name) then
        return 0
    else
        local roleid = status.roleid * 10000 + 1000 + serverid
        status.roleid = status.roleid + 1
        namedb.req.save(name, roleid)
        return roleid
    end
end

function response.gen_role(name)
    local roleid = cs(check_name(name))
    if roleid ~= 0 then
        userdb.req.set("status", skynet.packstring(status))
    end
    return roleid
end

function response.gen_item()
    local itemid = status.itemid * 10000 + 2000 + serverid
    status.itemid = status.itemid + 1
    userdb.req.set("status", skynet.packstring(status))
    return itemid
end
