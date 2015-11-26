local login = require "snax.loginserver"
local crypt = require "crypt"
local skynet = require "skynet"

local assert = assert
local print = print
local error = error
local string = string

local server = {
	host = "127.0.0.1",
	port = 8001,
    multilogin = true, -- allow same user login different server
	name = "login_master",
}

local server_list = {}
local user_online = {}
local user_login = {}

function gen_id(uid, server)
    return string.format("%s@%s", uid, server)
end

function get_gate(servername)
    local l = assert(server_list[servername], string.format("Unknown server %s.", servername))
    local gate
    for k, v in ipairs(l) do
        if not gate or gate.count > v.count then
            gate = v
        end
    end
    return gate
end

function server.auth_handler(token)
	-- the token is base64(user)@base64(server):base64(password)
	local user, server, password = token:match("([^@]+)@([^:]+):(.+)")
	user = crypt.base64decode(user)
	server = crypt.base64decode(server)
	password = crypt.base64decode(password)
	assert(password == "password")
	return server, user
end

function server.login_handler(server, uid, secret)
	print(string.format("%s@%s is login, secret is %s", uid, server, crypt.hexencode(secret)))
	local gameserver = assert(get_gate(server), "Unknown server")
    -- allow same user login different server
    local id = gen_id(uid, server)
    local subid
    if user_login[id] then
        error(string.format("user %s is already login", id))
    else
        user_login[id] = true
        local last = user_online[id]
        if last then
            skynet.call(last.address, "lua", "kick", uid, last.subid)
        end
        if user_online[id] then
            error(string.format("user %s is already online", id))
        end
        subid = tostring(skynet.call(gameserver.address, "lua", "login", uid, secret))
    end
    user_login[id] = nil
    user_online[id] = {address = gameserver.address, subid = subid, server = server}
    return string.format("%s@%s:%s", subid, gameserver.ip, gameserver.port)
end

local CMD = {}

function CMD.register_gate(conf, address)
    local i = {
        ip = conf.address,
        port = conf.port,
        address = address,
        count = 0,
    }
    local l = server_list[conf.servername]
    if l then
        l[#l+1] = i
    else
        server_list[conf.servername] = {i}
    end
end

function CMD.logout(uid, server, subid)
    local id = gen_id(uid, server)
	local u = user_online[id]
	if u then
		print(string.format("%s is logout", id))
		user_online[id] = nil
	end
end

function server.command_handler(command, ...)
	local f = assert(CMD[command])
	return f(...)
end

login(server)
