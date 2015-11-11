local skynet = require "skynet"
local snax = require "snax"

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.tostring,
}

local gate
local userid, subid
local accdb, userdb, tradedb
local account
local proto

local CMD = {}

function CMD.login(source, uid, sid, secret)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	gate = source
	userid = uid
	subid = sid
	-- you may load user data from database
    account = accdb.req.get(uid)
    if account then
        account = skynet.unpack(account)
    else
        account = {}
        accdb.req.set(uid, skynet.packstring(account))
    end
end

local function logout()
	if gate then
		skynet.call(gate, "lua", "logout", userid, subid)
	end
	skynet.exit()
end

function CMD.logout(source)
	-- NOTICE: The logout MAY be reentry
	skynet.error(string.format("%s is logout", userid))
	logout()
end

function CMD.afk(source)
	-- the connection is broken, but the user may back
	skynet.error(string.format("AFK"))
end

skynet.start(function()
    local master = snax.queryservice("dbmaster")
    accdb = snax.bind(master.req.get_slave("accountdb"))
    userdb = snax.bind(master.req.get_slave("userdb"))
    tradedb = snax.bind(master.req.get_slave("tradedb"))
    proto = snax.queryservice("proto")

	-- If you want to fork a work thread, you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(source, ...)))
	end)

	skynet.dispatch("client", function(_, _, msg)
		-- the simple ehco service
		skynet.sleep(10)	-- sleep a while
		skynet.ret(msg)

        local id = msg:byte(1) * 256 + msg:byte(2)
	end)
end)
