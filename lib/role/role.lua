local skynet = require "skynet"
local snax = require "snax"
local error_code = require "error"
local base = require "base"

local card = require "role.card"
local friend = require "role.friend"
local item = require "role.item"
local stage = require "role.stage"
local task = require "role.task"

local carddata = require "data.card"
local itemdata = require "data.item"
local stagedata = require "data.stage"
local taskdata = require "data.task"

local data

local role = {}

function role.init(userdata)
    data = userdata
    local server_mgr = snax.queryservice("server_mgr")
    data.server = snax.bind(server_mgr.req.get_server(1))
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
    for k, v in ipairs({card, friend, item, stage, task}) do
        v.init(data)
    end
end

function role.get_account_info(msg)
    return "account_info", data.account
end

function role.create_user(msg)
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

function role.enter_game(msg)
    local has = false
    for k, v in ipairs(data.account) do
        if v.id == msg.id then
            has = true
            break
        end
    end
    if not has then
        error(error_code.ROLE_NOT_EXIST)
    end
    local user = data.userdb.req.get(msg.id)
    if not user then
        error(error_code.ROLE_NOT_EXIST)
    end
    data.user = user
    data.friend = user.friend
    data.item = {}
    data.card = {}
    data.stage = {}
    data.task = {}
    local ret = {
        user = user,
        item = {},
        card = {},
        stage = {},
        task = {},
        friend = {},
    }
    for k, v in pairs(user.item) do
        data.item[k] = {v, assert(itemdata[v.itemid], string.format("No item data %d.", v.itemid))}
        ret.item[#ret.item+1] = v
    end
    for k, v in pairs(user.card) do
        data.card[k] = {v, assert(carddata[v.id], string.format("No card data %d.", v.id))}
        ret.card[#ret.card+1] = v
    end
    for k, v in pairs(user.stage) do
        data.stage[k] = {v, assert(stagedata[v.id], string.format("No stage data %d.", v.id))}
        ret.stage[#ret.stage+1] = v
    end
    for k, v in pairs(user.task) do
        data.task[k] = {v, assert(taskdata[v.id], string.format("No task data %d.", v.id))}
        ret.task[#ret.task+1] = v
    end
    for k, v in pairs(user.friend) do
        ret.friend[#ret.friend+1] = v
    end
    -- TODO: correct logic error
    return "user_all", ret
end

local proc = {}
for k, v in ipairs({card, friend, item, stage, task, role}) do
    for k1, v1 in pairs(v) do
        proc[k1] = v1
    end
end

return proc
