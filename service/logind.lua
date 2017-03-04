local login = require "snax.loginserver"
local crypt = require "crypt"
local skynet = require "skynet"
local cjson = require "cjson"

local assert = assert
local error = error
local string = string
local tonumber = tonumber

local server = {
	port = skynet.getenv("login"),
	multilogin = true,	-- allow same user login different server
}

local server_list = {}
local gate_list = {}
local user_online = {}
local user_login = {}
local webclient

local LOGIN_PASSWORD = 1
local LOGIN_PASSER = 2
local LOGIN_WEIXIN = 3
local LOGIN_QQ = 4

local auth_proc = {
    [LOGIN_PASSWORD] = function(user, data)
        return crypt.base64decode(data)
    end,
    [LOGIN_PASSER] = function(user, data)
        
    end,
    [LOGIN_WEIXIN] = function(user, data)
        local access_token, refresh_token = data:match("([^:]+):(.+)")
        access_token = crypt.base64decode(access_token)
        refresh_token = crypt.base64decode(refresh_token)
        -- NOTICE: umeng uid is unionid, not openid if unionid exist.
        local result, content = skynet.call(webclient, "lua", "request", 
            "https://api.weixin.qq.com/sns/userinfo", {openid=user, access_token=access_token, lang="zh_CN"})
        -- print(result, content)
        local content = cjson.decode(content)
        if content.errcode ~= 0 then
            error(content.errmsg)
        end
    end,
    [LOGIN_QQ] = function(user, data)
        
    end,
}

skynet.init(function()
    webclient = skynet.queryservice("webclient")
end)

function server.auth_handler(token, other)
	-- the token is base64(user)@base64(sname):loginType
	local user, sname, loginType = token:match("([^@]+)@([^:]+):(.+)")
	user = crypt.base64decode(user)
	sname = crypt.base64decode(sname)
	loginType = tonumber(loginType)
    local proc = auth_proc[loginType]
    if not proc then
        error(string.format("Unsupported login type %d.", loginType))
    end
    local password = proc(user, other)
    local info = server_list[sname]
    if not info then
        error(string.format("Unknown server %s.", sname))
    end
    local account, errmsg = skynet.call(info.address, "lua", "gen_account", loginType, user, password)
    if errmsg then
        error(errmsg)
    end
    return sname, account.id
end

function server.login_handler(sname, uid, secret)
	skynet.error(string.format("%d is login, secret is %s", uid, crypt.hexencode(secret)))
	local gameserver = assert(server_list[sname], string.format("Unknown server %s.", sname))
    -- allow same user login different server
    if gameserver.shutdown then
    	error(string.format("server %s shutdown", sname))
    end
    if user_login[uid] then
        error(string.format("user %d is already login", uid))
    end
	user_login[uid] = true
	local last = user_online[uid]
	if last then
	    skynet.call(last.gate.address, "lua", "kick", uid)
	end
	if user_online[uid] then
        user_login[uid] = nil
	    error(string.format("user %d is already online", uid))
	end
    local gate = gameserver.gate
	local subid = skynet.call(gate.address, "lua", "login", uid, secret, sname, gameserver.id)
    user_online[uid] = {gate=gate, subid=subid, server=sname}
    user_login[uid] = nil
    return string.format("%d@%d@%s:%s", uid, subid, gate.ip, gate.port)
end

local CMD = {}

function CMD.register_gate(conf, address)
    local name = conf.servername
    assert(not gate_list[name], string.format("gate %s already exist", name))
	gate_list[name] = {
        ip = conf.ip,
        port = conf.port,
        address = address,
    }
end

function CMD.register_server(conf, gatename, address)
    local name = conf.servername
    assert(not server_list[name], string.format("server %s already exist", name))
    local gate = assert(gate_list[gatename], string.format("no gate %s", gatename))
    server_list[name] = {
        id = conf.serverid,
        gate = gate,
        shutdown = false,
        address = address,
    }
end

function CMD.unregister_server(name)
    local info = assert(server_list[name], string.format("no server %s", name))
    info.shutdown = true
end

function CMD.logout(id)
	local u = user_online[id]
	if u then
		skynet.error(string.format("%d is logout from loginserver", id))
		user_online[id] = nil
	end
end

function server.command_handler(command, ...)
	local f = assert(CMD[command])
	return f(...)
end

login(server)
