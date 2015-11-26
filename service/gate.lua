local msgserver = require "snax.msgserver"
local crypt = require "crypt"
local skynet = require "skynet"
local snax = require "sanx"

local error = error
local assert = assert
local string = string

local loginservice = tonumber(...)

local server = {}
local users = {}
local username_map = {}
local internal_id = 0
local agent_mgr = snax.queryservice("agent_mgr")
local servername

-- login server disallow multi login, so login_handler never be reentry
-- call by login server
function server.login_handler(uid, secret)
	if users[uid] then
		error(string.format("%s is already login", uid))
	end

	internal_id = internal_id + 1
	local id = internal_id	-- don't use internal_id directly
	local username = msgserver.username(uid, id, servername)

	-- you can use a pool to alloc new agent
    local agent = agent_mgr.req.get_agent()
	local u = {
		username = username,
		agent = agent,
		uid = uid,
		subid = id,
	}

	-- trash subid (no used)
	skynet.call(agent, "lua", "login", uid, id, secret, servername)

	users[uid] = u
	username_map[username] = u

	msgserver.login(username, secret)

	-- you should return unique subid
	return id
end

-- call by agent
function server.logout_handler(uid, subid)
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
		msgserver.logout(u.username)
		users[uid] = nil
		username_map[u.username] = nil
        agent_mgr.req.free_agent(u.agent)
		skynet.call(loginservice, "lua", "logout", uid, servername, subid)
	end
end

-- call by login server
function server.kick_handler(uid, subid)
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
        skynet.call(u.agent, "lua", "logout", uid, subid)
	end
end

-- call by self (when socket disconnect)
function server.disconnect_handler(username)
	local u = username_map[username]
	if u then
		skynet.call(u.agent, "lua", "afk")
	end
end

-- call by self (when recv a request from client)
function server.request_handler(username, msg)
	local u = username_map[username]
	return skynet.tostring(skynet.rawcall(u.agent, "client", msg))
end

-- call by self (when gate open)
function server.register_handler(conf)
    servername = assert(conf.servername)
	skynet.call(loginservice, "lua", "register_gate", conf, skynet.self())
end

msgserver.start(server)

