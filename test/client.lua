local root = "../../"
package.cpath = "luaclib/?.so"
package.path = root.."lib/?.lua;./lualib/?.lua;./lualib/?/init.lua"

local socket = require "clientsocket"
local crypt = require "skynet.crypt"
local sprotoloader = require "sprotoloader"
local proto = require "proto"

local assert = assert
local print = print
local tonumber = tonumber
local error = error
local string = string

if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end

local spfile = root.."proto/proto.sp"
sprotoloader.register(spfile, 1)
local sproto = sprotoloader.load(1)

local fd = assert(socket.connect("192.168.2.103", 8001))

local function writeline(fd, text)
	socket.send(fd, text .. "\n")
end

local function unpack_line(text)
	local from = text:find("\n", 1, true)
	if from then
		return text:sub(1, from-1), text:sub(from+1)
	end
	return nil, text
end

local last = ""

local function unpack_f(f)
	local function try_recv(fd, last)
		local result
		result, last = f(last)
		if result then
			return result, last
		end
		local r = socket.recv(fd)
		if not r then
			return nil, last
		end
		if r == "" then
			error "Server closed"
		end
		return f(last .. r)
	end

	return function()
		while true do
			local result
			result, last = try_recv(fd, last)
			if result then
				return result
			end
			socket.usleep(100)
		end
	end
end

local readline = unpack_f(unpack_line)

local challenge = crypt.base64decode(readline())

local clientkey = crypt.randomkey()
writeline(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
local secret = crypt.dhsecret(crypt.base64decode(readline()), clientkey)

print("sceret is ", crypt.hexencode(secret))

local hmac = crypt.hmac64(challenge, secret)
writeline(fd, crypt.base64encode(hmac))

local token = {
	server = "sample",
	user = "hello",
	pass = "password",
}

local function encode_token(token)
	return string.format("%s@%s:%s",
		crypt.base64encode(token.user),
		crypt.base64encode(token.server),
		crypt.base64encode(token.pass))
end

local etoken = crypt.desencode(secret, encode_token(token))
writeline(fd, crypt.base64encode(etoken))

local result = readline()
print(result)
local code = tonumber(string.sub(result, 1, 3))
assert(code == 200)
socket.close(fd)

local subid, gate_ip, gate_port = crypt.base64decode(string.sub(result, 5)):match("([^@]+)@([^:]+):(.+)")
gate_port = tonumber(gate_port)

print(string.format("login ok, subid=%s, gate ip=%s, gate port=%d.", subid, gate_ip, gate_port))

----- connect to game server

local function send_request(session, msgname, msg)
    if type(msg) == "table" then
        for k, v in pairs(msg) do
            print(k, v)
        end
    end
    msg = msg or ""
    if sproto:exist_type(msgname) then
        msg = sproto:pencode(msgname, msg)
    end
    local id = assert(proto.get_id(msgname))
    local content = string.pack(">I2", id) .. msg
	local size = #content + 4
	local package = string.pack(">I2", size)..content..string.pack(">I4", session)
	socket.send(fd, package)
	return msgname, session
end

local function recv_response(v)
	local size = #v - 5
	local content, ok, session = string.unpack("c"..tostring(size).."B>I4", v)
    if ok ~= 0 then
        local id = content:byte(1) * 256 + content:byte(2)
        local msg = content:sub(3)
        local msgname = assert(proto.get_name(id))
        if sproto:exist_type(msgname) then
            msg = sproto:pdecode(msgname, msg)
        end
        if type(msg) == "table" then
            for k, v in pairs(msg) do
                print(k, v)
            end
        end
        return true, msgname, session
    else
        return false, session
    end
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end
	return text:sub(3, 2+s), text:sub(3+s)
end

local readpackage = unpack_f(unpack_package)

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.send(fd, package)
end

local index = 1

print("connect", gate_ip, gate_port)
fd = assert(socket.connect(gate_ip, gate_port))
last = ""

local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server), crypt.base64encode(subid), index)
local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))

print(readpackage())
print("===>", send_request(0, "get_account_info"))
print("<===", recv_response(readpackage()))
print("===>", send_request(1, "heart_beat", {time=os.time()}))
print("<===", recv_response(readpackage()))

print("disconnect")
socket.close(fd)
