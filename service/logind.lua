local login = require "snax.loginserver"
local crypt = require "crypt"
local skynet = require "skynet"
local util = require "util"

local assert = assert
local error = error
local string = string

local server = {
	port = skynet.getenv("login"),
	multilogin = true,	-- allow same user login different server
	name = "login_master",
}

local gen_id = util.gen_id
local server_list = {}
local gate_list = {}
local user_online = {}
local user_login = {}

function server.auth_handler(token)
	-- the token is base64(user)@base64(server):base64(password)
	local user, server, password = token:match("([^@]+)@([^:]+):(.+)")
	user = crypt.base64decode(user)
	server = crypt.base64decode(server)
	password = crypt.base64decode(password)
	assert(password == "password", "Invalid password")
	return server, user
end

function server.login_handler(server, uid, secret)
    local id = gen_id(uid, server)
	skynet.error(string.format("%s is login, secret is %s", id, crypt.hexencode(secret)))
	local gameserver = assert(server_list[server], "Unknown server")
    -- allow same user login different server
    if gameserver.shutdown then
    	error(string.format("server %s shutdown", server))
    end
    if user_login[id] then
        error(string.format("user %s is already login", id))
    end
	user_login[id] = true
	local last = user_online[id]
	if last then
	    skynet.call(last.gate.address, "lua", "kick", id)
	end
	if user_online[id] then
        user_login[id] = nil
	    error(string.format("user %s is already online", id))
	end
    local gate = gameserver.gate
	local subid = skynet.call(gate.address, "lua", "login", uid, secret, server, gameserver.id)
    user_online[id] = {gate = gate, subid = subid, server = server}
    user_login[id] = nil
    return string.format("%d@%s:%s", subid, gate.ip, gate.port)
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

function CMD.register_server(conf, gatename)
    local name = conf.servername
    assert(not server_list[name], string.format("server %s already exist", name))
    local gate = assert(gate_list[gatename], string.format("no gate %s", gatename))
    server_list[name] = {
        id = conf.serverid,
        gate = gate,
        shutdown = false,
    }
end

function CMD.unregister_server(name)
    local server = assert(server_list[name], string.format("no server %s", name))
    server.shutdown = true
end

function CMD.logout(id)
	local u = user_online[id]
	if u then
		skynet.error(string.format("%s is logout from loginserver", id))
		user_online[id] = nil
	end
end

function server.command_handler(command, ...)
	local f = assert(CMD[command])
	return f(...)
end

login(server)
