local skynet = require "skynet"
local snax = require "snax"
local error_code = require "error"
local base = require "base"

local accdb, userdb, tradedb
local server
local userid, subid
local account, user

local role = {}

function role.login(userid, subid)
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

function role.logout()
    
end

function role.get_account_info(msg)
    return "account_info", account
end

function role.create_user(msg)
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

local function init()
    
end

function role.enter_game(msg)
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
    init()
end

return role
