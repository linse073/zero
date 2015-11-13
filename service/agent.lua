local skynet = require "skynet"
local snax = require "snax"
local proto = require "proto"
local sprotoloader = require "sprotoloader"
local error_code = require "error"
local base = require "base"

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
    unpack = skynet.tostring,
}

local sproto
local accdb, userdb, tradedb
local gate
local server
local userid, subid
local account
local user

local CMD = {}

function CMD.login(source, uid, sid, secret)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	gate = source
	userid = uid
	subid = sid
    local server_mgr = snax.queryservice("server_mgr")
    server = snax.bind(server_mgr.req.get_server(1))
	-- you may load user data from database
    local master = snax.queryservice("dbmaster")
    accdb = snax.bind(master.req.get_slave("accountdb"))
    userdb = snax.bind(master.req.get_slave("userdb"))
    tradedb = snax.bind(master.req.get_slave("tradedb"))
    account = accdb.req.get(uid)
    if account then
        account = skynet.unpack(account)
    else
        account = {}
        -- save account after create user
        -- accdb.req.set(uid, skynet.packstring(account))
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

local MSG = {}

function MSG.get_account_info(msg)
    return "account_info", account
end

function MSG.create_user(msg)
    if #account >= base.MAX_ROLE then
        error(error_code.MAX_ROLE)
    end
    local roleid = server.req.gen_role(msg.name)
    if roleid == 0 then
        error(error_code.ROLE_NAME_EXIST)
    end
    local su = {
        name = msg.name,
        id = roleid,
        prof = msg.prof,
        level = 1,
    }
    account[#account+1] = su
    accdb.req.save(userid, skynet.packstring(account))
    local u = {
        name = msg.name,
        id = roleid,
        prof = msg.prof,
        level = 1,
        exp = 0,
        charge = 0,
        vip = 0,
        rmb = 0,
        money = 0,
        rank = 0,
        arena_count = 0,
        charge_arena = 0,
        fight_point = 0,
        login_time = 0,
        last_login_time = 0,
        logout_time = 0,

        item = {},
        card = {},
        stage = {},
        task = {},
        friend = {},
    }
    userdb.req.save(roleid, skynet.packstring(u))
    return "simple_user", su
end

function MSG.enter_game(msg)
    local has = false
    for k, v in ipairs(account) do
        if v.id == msg.id then
            has = true
            break
        end
    end
    if not has then
        error(error_code.ROLE_NOT_EXIST)
    end
    user = userdb.req.get(msg.id)
    if not user then
        error(error_code.ROLE_NOT_EXIST)
    end
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
        local msgname = assert(proto.get_name(id))
        if sproto:exist_type(msgname) then
            arg = sproto:pdecode(msgname, arg)
        end
        local f = assert(MSG[msgname])
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
        local rid = assert(proto.get_id(rmsg))
        return string.pack(">I2", rid) .. info
	end)
end)
