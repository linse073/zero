local skynet = require "skynet"

local ipairs = ipairs
local assert = assert
local tonumber = tonumber

local maildb
local userdb
local role_mgr

local CMD = {}

function CMD.broadcast(info)
    local index
    local list = {}
    repeat
        local res = skynet.call(userdb, "lua", "scan", index)
        index = res[1]
        for k, v in ipairs(res[2]) do
            if not list[v] then
                CMD.send(tonumber(v), info)
                list[v] = true
            end
        end
    until index == "0"
end

function CMD.send(roleid, info)
    local agent = skynet.call(role_mgr, "lua", "get", roleid)
    if agent then
        skynet.call(agent, "lua", "mail", info)
    else
        skynet.call(maildb, "lua", "lpush", roleid, skynet.packstring(info))
    end
end

function CMD.get(roleid)
    local m = skynet.call(maildb, "lua", "lrange", roleid, 0, -1)
    if m then
        local r = {}
        for k, v in ipairs(m) do
            r[k] = skynet.unpack(v)
        end
        skynet.call(maildb, "lua", "del", roleid)
        return r
    end
end

skynet.start(function()
    local master = skynet.queryservice("dbmaster")
    maildb = skynet.call(master, "lua", "get", "maildb")
    userdb = skynet.call(master, "lua", "get", "userdb")
    role_mgr = skynet.queryservice("role_mgr")

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            f(...)
        else
            skynet.retpack(f(...))
        end
	end)
end)
