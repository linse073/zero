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

function server.id(uid, server)
    return string.format("%s@%s", uid, server)
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
	local gameserver = assert(server_list[server], "Unknown server")
    -- allow same user login different server
    local id = server.id(uid, server)
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
        subid = tostring(skynet.call(gameserver, "lua", "login", uid, secret))
    end
    user_login[id] = nil
    user_online[id] = {address = gameserver, subid = subid, server = server}
	return subid
end

local CMD = {}

function CMD.register_gate(server, address)
	server_list[server] = address
end

function CMD.logout(uid, server, subid)
    local id = server.id(uid, server)
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
