local login = require "snax.loginserver"
local crypt = require "crypt"
local skynet = require "skynet"

local assert = assert
local print = print
local error = error
local string = string

local server = require(skynet.getenv("config")).login
local ip = skynet.getenv("ip")

local server_list = {}
local user_online = {}
local user_login = {}

function gen_id(uid, server)
    return string.format("%s@%s", uid, server)
end

function get_gate(servername)
    local l = server_list[servername]
    if not l then
        error(string.format("Unknown server %s.", servername))
    end
    local gate
    for k, v in pairs(l) do
        if not gate or gate.count > v.count then
            gate = v
        end
    end
    if not gate then
        error(string.format("Unknown server %s.", servername))
    end
    return gate
end

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
	print(string.format("%s@%s is login, secret is %s", uid, server, crypt.hexencode(secret)))
	local gate = get_gate(server)
    -- allow same user login different server
    local id = gen_id(uid, server)
    local subid
    if user_login[id] then
        error(string.format("user %s is already login", id))
    else
        user_login[id] = true
        local last = user_online[id]
        if last then
            skynet.call(last.gate.address, "lua", "kick", uid, last.subid)
        end
        if user_online[id] then
            error(string.format("user %s is already online", id))
        end
        subid = skynet.call(gate.address, "lua", "login", uid, secret)
        gate.count = gate.count + 1
    end
    user_login[id] = nil
    user_online[id] = {gate = gate, subid = subid, server = server}
    return string.format("%d@%s:%s", subid, ip, gate.port)
end

local CMD = {}

function CMD.register_gate(conf, servername, address)
    local i = {
        port = conf.port,
        address = address,
        count = 0,
    }
    local l = server_list[servername]
    if not l then
        l = {}
        server_list[servername] = l
    end
    l[address] = i
end

function CMD.unregister_gate(servername, address)
    local l = assert(server_list[servername], string.format("Unknown server %s.", servername))
    l[address] = nil
end

function CMD.logout(uid, server, subid)
    local id = gen_id(uid, server)
	local u = user_online[id]
	if u then
		print(string.format("%s is logout", id))
        local gate = u.gate
        gate.count = gate.count - 1
		user_online[id] = nil
	end
end

function server.command_handler(command, ...)
	local f = assert(CMD[command])
	return f(...)
end

login(server)
