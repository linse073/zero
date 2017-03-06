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
	-- multilogin = true,	-- allow same user login different server
}

local server_list = {}
local gate_list = {}
local user_online = {}
local user_login = {}
local webclient

local auth_proc = {
    function(user, data) -- password login
        local password, register = data:match("([^:]+):(.+)")
        password = crypt.base64decode(password)
        register = (crypt.base64decode(register)=="true")
        return password, register
    end,
    function(user, data) -- passer login
        
    end,
    function(user, data) -- weixin login
        local access_token, refresh_token = data:match("([^:]+):(.+)")
        access_token = crypt.base64decode(access_token)
        refresh_token = crypt.base64decode(refresh_token)
        -- NOTICE: umeng uid is unionid, not openid if unionid exist.
        local result, content = skynet.call(webclient, "lua", "request", 
            "https://api.weixin.qq.com/sns/userinfo", {openid=user, access_token=access_token, lang="zh_CN"})
        -- print(result, content)
        if not result then
            error("network error")
        end
        local content = cjson.decode(content)
        if content.errcode then
            error(content.errmsg)
        end
    end,
    function(user, data) -- qq login
        
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
    local password, register = proc(user, other)
    return {
        server = sname,
        loginType = loginType,
        uid = user,
        password = password,
        register = register,
    }
end

function server.login_handler(info, secret)
    local sname = info.server
	local gameserver = server_list[sname]
    if not gameserver then
        error(string.format("Unknown server %s.", sname))
    end
    -- allow same user login different server
    if gameserver.shutdown then
    	error(string.format("server %s shutdown", sname))
    end
    local new, account, errmsg = skynet.call(gameserver.address, "lua", "gen_account", info.loginType, info.uid, info.password, info.register)
    if errmsg then
        error(errmsg)
    end
    local id = account.id
	skynet.error(string.format("%d is login, secret is %s", id, crypt.hexencode(secret)))
    if user_login[id] then
        error(string.format("user %d is already login", id))
    end
	user_login[id] = true
	local last = user_online[id]
	if last then
	    skynet.call(last.gate.address, "lua", "kick", id)
	end
	if user_online[id] then
        user_login[id] = nil
	    error(string.format("user %d is already online", id))
	end
    local gate = gameserver.gate
	local subid = skynet.call(gate.address, "lua", "login", id, secret, sname, gameserver.id)
    user_online[id] = {gate=gate, subid=subid, server=sname}
    user_login[id] = nil
    return string.format("%d@%d@%s:%s", id, subid, gate.ip, gate.port), id, new
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
