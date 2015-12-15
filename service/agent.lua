local skynet = require "skynet"
local role = require "role.role"
local timer = require "timer"
local share = require "share"

local assert = assert
local pcall = pcall
local type = type
local string = string

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
    unpack = skynet.tostring,
}

local proc = role.get_proc()
local msg
local name_msg
local base
local sproto
local error_code

local data

local CMD = {}

function CMD.login(source, uid, sid, secret, servername)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
    data = {
        gate = source,
        userid = uid,
        subid = sid,
        servername = servername,
    }
    role.init(data)
end

local function logout()
    local d = data
    data = nil
    skynet.error(string.format("%s is logout", d.userid))
    role.exit()
    skynet.call(d.gate, "lua", "logout", d.userid, d.subid)
end

function CMD.logout(source, uid, sid)
	-- NOTICE: The logout MAY be reentry
    if data and data.userid == uid and data.subid == sid then
        logout()
    end
end

function CMD.afk(source)
	-- the connection is broken, but the user may back
    if data then
        skynet.error(string.format("%s afk", data.userid))
    end
end

function CMD.exit(source)
    assert(not data, string.format("Agent exit error %s.", data.userid))
	skynet.exit()
end

function CMD.routine(source, key)
    timer.call_routine(key)
end

function CMD.once_routine(source, key)
    timer.call_once_routine(key)
end

function CMD.day_routine(source, key)
    timer.call_day_routine(key)
end

skynet.start(function()
    msg = share.msg
    name_msg = share.name_msg
    base = share.base
    sproto = share.sproto
    error_code = share.error_code

	-- If you want to fork a work thread, you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            f(source, ...)
        else
            skynet.ret(skynet.pack(f(source, ...)))
        end
	end)

	skynet.dispatch("client", function(_, _, content)
        local id = content:byte(1) * 256 + content:byte(2)
        local arg = content:sub(3)
        local msgname = assert(msg[id], string.format("No protocol %d.", id))
        if sproto:exist_type(msgname) then
            arg = sproto:pdecode(msgname, arg)
        end
        local f = assert(proc[msgname], string.format("No protocol procedure %s.", msgname))
        local ok, rmsg, info = pcall(f, arg)
        if not ok then
            if type(rmsg) == "string" then
                skynet.error(rmsg)
                info = {code = error_code.INTERNAL_ERROR}
            else
                assert(type(rmsg) == "table")
                info = rmsg
            end
            info.msgid = id
            rmsg = "error_code"
        elseif rmsg == "user_update" then
            info.msgid = id
        end
        if sproto:exist_type(rmsg) then
            info = sproto:pencode(rmsg, info)
        end
        local rid = assert(name_msg[rmsg], string.format("No protocol %s.", rmsg))
        skynet.ret(string.pack(">I2", rid) .. info)
	end)
end)
