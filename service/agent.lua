local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local role = require "role.role"
local timer = require "timer"
local share = require "share"

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
    unpack = skynet.tostring,
}

local sproto
local gate
local data
local proc
local msg
local name_msg

local CMD = {}

function CMD.login(source, uid, sid, secret)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	gate = source
    data = {
        userid = uid,
        subid = sid,
    }
    role.init(data)
end

local function logout()
	if gate then
		skynet.call(gate, "lua", "logout", data.userid, data.subid)
	end
    role.exit()
	-- skynet.exit()
end

function CMD.logout(source)
	-- NOTICE: The logout MAY be reentry
	skynet.error(string.format("%s is logout", data.userid))
	logout()
end

function CMD.afk(source)
	-- the connection is broken, but the user may back
	skynet.error(string.format("AFK"))
end

function CMD.routine(source, key)
    timer.call_routine(key)
end

function CMD.day_routine(source, key)
    timer.call_day_routine(key)
end

skynet.start(function()
    math.randomseed(skynet.time())
    sproto = sprotoloader.load(1)
    proc = role.get_proc()
    msg = share.msg
    name_msg = share.name_msg

	-- If you want to fork a work thread, you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(source, ...)))
	end)

	skynet.dispatch("client", function(_, _, msg)
        local id = msg:byte(1) * 256 + msg:byte(2)
        local arg = msg:sub(3)
        local msgname = assert(msg[id], string.format("No protocol %d.", id))
        if sproto:exist_type(msgname) then
            arg = sproto:pdecode(msgname, arg)
        end
        local f = assert(proc[msgname], string.format("No protocol procedure %s.", msgname))
        local ok, rmsg, info = pcall(f, arg)
        if not ok then
            info = {
                id = id,
                code = rmsg,
            }
            rmsg = "error_code"
        end
        if sproto:exist_type(rmsg) then
            info = sproto:pencode(rmsg, info)
        end
        local rid = assert(name_msg[rmsg], string.format("No protocol %s.", rmsg))
        return string.pack(">I2", rid) .. info
	end)
end)
