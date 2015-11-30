local skynet = require "skynet"
local snax = require "snax"
local timer = require "timer"
local share = require "share"
local notify = require "notify"

local card = require "role.card"
local friend = require "role.friend"
local item = require "role.item"
local stage = require "role.stage"
local task = require "role.task"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local math = math

local error_code
local base
local data
local module = {card, friend, item, stage, task}
local role = {}
local proc = {}
local role_mgr

for k, v in ipairs(module) do
    for k1, v1 in pairs(v.get_proc()) do
        proc[k1] = v1
    end
end

skynet.init(function()
    error_code = share.error_code
    base = share.base
    role_mgr = skynet.queryservice("role_mgr")
end)

function role.init(userdata)
    data = userdata
    local server_mgr = snax.queryservice("server_mgr")
    data.server = snax.bind(server_mgr.req.get_server(data.servername))
	-- you may load user data from database
    local master = snax.queryservice("dbmaster")
    data.accdb = snax.bind(master.req.get_slave("accountdb"))
    data.userdb = snax.bind(master.req.get_slave("userdb"))
    local account = data.accdb.req.get(uid)
    if account then
        data.account = skynet.unpack(account)
    else
        data.account = {} -- save account after create user
    end
    for k, v in ipairs(module) do
        v.init(data)
    end
end

function role.exit()
    for k, v in ipairs(module) do
        v.exit()
    end
    timer.del_routine("save_role")
    timer.del_day_routine("update_day")
    local user = data.user
    if user then
        skynet.call(role_mgr, "lua", "logout", user.id)
    end
    notify.exit()
    role.save_routine()
    data = nil
end

function role.update_day()
    local pt = task.update_day()
    notify.add("update_day", {task = pt})
end

function role.save_routine()
    local user = data.user
    if user then
        if data.suser.level ~= user.level then
            data.accdb.req.save(data.userid, skynet.packstring(data.account))
        end
        data.userdb.req.save(user.id, skynet.packstring(user))
    end
end

function role.get_proc()
    return proc
end

-------------------protocol process--------------------------

function proc.notify_info(msg)
    return notify.send()
end

function proc.heart_beat(msg)
    timer.del_day_routine("afk")
    return "heart_beat_response", {time = msg.time, server_time = skynet.time()}
end

function proc.get_account_info(msg)
    return "account_info", data.account
end

function proc.create_user(msg)
    local account = data.account
    if #account >= base.MAX_ROLE then
        error(error_code.MAX_ROLE)
    end
    local roleid = data.server.req.gen_role(msg.name)
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
    data.accdb.req.save(data.userid, skynet.packstring(account))
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
    data.userdb.req.save(roleid, skynet.packstring(u))
    return "simple_user", su
end

function proc.enter_game(msg)
    local suser
    for k, v in ipairs(data.account) do
        if v.id == msg.id then
            suser = v
            break
        end
    end
    if not suser then
        error(error_code.ROLE_NOT_EXIST)
    end
    local user = data.userdb.req.get(msg.id)
    if not user then
        error(error_code.ROLE_NOT_EXIST)
    end
    math.randomseed(skynet.time() + msg.id)
    data.suser = suser
    data.user = user
    local ret = {user = user}
    for k, v in ipairs(module) do
        local key, pack = v.enter()
        ret[key] = pack
    end
    timer.add_routine("save_role", role.save_routine, 30000)
    timer.add_day_routine("update_day", role.update_day)
    skynet.call(role_mgr, "lua", "enter", user.id, skynet.self())
    return "user_all", ret
end

return role
