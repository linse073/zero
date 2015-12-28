local skynet = require "skynet"
local timer = require "timer"
local share = require "share"
local notify = require "notify"
local util = require "util"

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
local randomseed = math.randomseed

local merge_table = util.merge_table
local expdata
local error_code
local base
local data
local module = {card, friend, item, stage, task}
local role = {}
local proc = {}
local role_mgr

for k, v in ipairs(module) do
    merge_table(proc, v.get_proc())
end

skynet.init(function()
    expdata = share.expdata
    error_code = share.error_code
    base = share.base
    role_mgr = skynet.queryservice("role_mgr")
end)

function role.init(userdata)
    data = userdata
    data.heart_beat = 0
    timer.add_routine("heart_beat", role.heart_beat, 300)
    local server_mgr = skynet.queryservice("server_mgr")
    data.server = skynet.call(server_mgr, "lua", "get", data.serverid)
	-- you may load user data from database
    local master = skynet.queryservice("dbmaster")
    data.accdb = skynet.call(master, "lua", "get", "accountdb")
    data.userdb = skynet.call(master, "lua", "get", "userdb")
    local account = skynet.call(data.accdb, "lua", "get", data.userkey)
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
    timer.del_routine("heart_beat")
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
            skynet.call(data.accdb, "lua", "save", data.userkey, skynet.packstring(data.account))
        end
        skynet.call(data.userdb, "lua", "save", user.id, skynet.packstring(user))
    end
end

function role.heart_beat()
    if data.heart_beat == 0 then
        skynet.error(string.format("heart beat kick user %s %d.", data.userid, data.subid))
        skynet.call(data.gate, "lua", "kick", data.userid, data.subid) -- data is nil
    else
        data.heart_beat = 0
    end
end

function role.add_exp(exp)
    local user = data.user
    local oldExp = user.exp
    user.exp = user.exp + exp
    local maxExpLevel = base.MAX_LEVEL - 1
    local ed = assert(expdata[maxExpLevel], string.format("No max exp data %d.", maxExpLevel))
    if user.exp > ed.HeroExp then
        user.exp = ed.HeroExp
    end
    if oldExp ~= user.exp then
        local oldLevel = user.level
        while true do
            local expd = assert(expdata[user.level], string.format("No exp data %d.", user.level))
            if user.exp < expd.HeroExp then
                break
            end
            user.level = user.level + 1
        end
        local puser = {exp = user.exp}
        local ptask
        if oldLevel ~= user.level then
            puser.level = user.level
            ptask = task.update_level(oldLevel, user.level)
        end
        return puser, ptask
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
    data.heart_beat = data.heart_beat + 1
    return "heart_beat_response", {time = msg.time, server_time = skynet.time()*100}
end

function proc.get_account_info(msg)
    return "account_info", {user = data.account}
end

function proc.create_user(msg)
    local account = data.account
    if #account >= base.MAX_ROLE then
        error{code = error_code.MAX_ROLE}
    end
    local roleid = skynet.call(data.server, "lua", "gen_role", msg.name)
    if roleid == 0 then
        error{code = error_code.ROLE_NAME_EXIST}
    end
    local su = {
        name = msg.name,
        id = roleid,
        prof = msg.prof,
        level = 1,
    }
    account[#account+1] = su
    skynet.call(data.accdb, "lua", "save", data.userkey, skynet.packstring(account))
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
    skynet.call(data.userdb, "lua", "save", roleid, skynet.packstring(u))
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
        error{code = error_code.ROLE_NOT_EXIST}
    end
    local user = skynet.call(data.userdb, "lua", "get", msg.id)
    if not user then
        error{code = error_code.ROLE_NOT_EXIST}
    end
    user = skynet.unpack(user)
    randomseed(skynet.time() + msg.id)
    data.suser = suser
    data.user = user
    local ret = {user = user}
    for k, v in ipairs(module) do
        local key, pack = v.enter()
        ret[key] = pack
    end
    timer.add_routine("save_role", role.save_routine, 300)
    timer.add_day_routine("update_day", role.update_day)
    skynet.call(role_mgr, "lua", "enter", user.id, skynet.self())
    return "user_all", ret
end

return role
