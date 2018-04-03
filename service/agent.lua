local skynet = require "skynet"
local role = require "game.role"
local timer = require "timer"
local share = require "share"
local notify = require "notify"
local util = require "util"

local assert = assert
local pcall = pcall
local type = type
local string = string

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
    unpack = skynet.tostring,
}

local proc = role.init_module()
local msg
local name_msg
local base
local sproto
local error_code
local cz
local data

local CMD = {}
util.timer_wrap(CMD)

function CMD.login(info)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%d is login", info.userid))
	data = info
    role.init(data)
end

local function logout()
    local d = data
    data = nil
    skynet.error(string.format("%d is logout from agent", d.userid))
    role.exit()
    skynet.call(d.gate, "lua", "logout", d.userid)
end

function CMD.logout()
	-- NOTICE: The logout MAY be reentry
    if data then
        logout()
    end
end

function CMD.afk()
	-- the connection is broken, but the user may back
    if data then
        skynet.error(string.format("%d afk", data.userid))
	role.afk()
    end
end

function CMD.btk(addr)
    if data then
        skynet.error(string.format("%d btk", data.userid))
	role.bfk(addr)
    end
end

function CMD.exit()
    assert(not data, string.format("Agent exit error %d.", data.userid))
	skynet.exit()
end

function CMD.notify(msg, info)
    notify.add(msg, info)
end

function CMD.get_info()
    return data.user
end

function CMD.get_rank_info()
    return data.rank_info
end

function CMD.action(otype, info)
    role.action(otype, info)
end

function CMD.action_info(otype, id)
    return role.action_info(otype, id)
end

function CMD.update_rank()
    role.update_rank()
end

skynet.start(function()
    msg = share.msg
    name_msg = share.name_msg
    base = share.base
    sproto = share.sproto
    error_code = share.error_code
	cz = share.cz

	-- If you want to fork a work thread, you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            f(...)
        else
            skynet.retpack(f(...))
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
            cz.over()
        if not ok then
            if type(rmsg) == "string" then
                skynet.error(rmsg)
                info = {code = error_code.INTERNAL_ERROR}
            else
                assert(type(rmsg) == "table")
                info = rmsg
            end
            rmsg = "error_code"
        end
        if sproto:exist_type(rmsg) then
            info = sproto:pencode(rmsg, info)
        end
        local rid = assert(name_msg[rmsg], string.format("No protocol %s.", rmsg))
        skynet.ret(string.pack(">I2", rid) .. info)
	end)
end)
