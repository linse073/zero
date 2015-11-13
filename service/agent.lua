local skynet = require "skynet"
local proto = require "proto"
local sprotoloader = require "sprotoloader"
local proc = require "role.role"

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
    unpack = skynet.tostring,
}

local sproto
local gate
local data

local CMD = {}

function CMD.login(source, uid, sid, secret)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	gate = source
    data = {
        userid = uid,
        subid = sid,
    }
    proc.init(data)
end

local function logout()
	if gate then
		skynet.call(gate, "lua", "logout", data.userid, data.subid)
	end
	skynet.exit()
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

skynet.start(function()
    sproto = sprotoloader.load(1)

	-- If you want to fork a work thread, you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(source, ...)))
	end)

	skynet.dispatch("client", function(_, _, msg)
        local id = msg:byte(1) * 256 + msg:byte(2)
        local arg = msg:sub(3)
        local msgname = assert(proto.get_name(id), string.format("No protocol %d.", id))
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
        local rid = assert(proto.get_id(rmsg), string.format("No protocol %s.", rmsg))
        return string.pack(">I2", rid) .. info
	end)
end)
