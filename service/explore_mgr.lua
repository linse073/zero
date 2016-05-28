local skynet = require "skynet"
local sharedata = require "sharedata"
local timer = require "timer"
local queue = require "skynet.queue"

local ipairs = ipairs
local assert = assert
local string = string
local math = math
local floor = math.floor

local cs = queue()
local explore_area = {}
local role_list = {}
local save_list = {}
local exploredb

local CMD = {}

local function save()
    for k, v in pairs(save_list) do
        if v then
            skynet.call(exploredb, "lua", "save", k, skynet.packstring(v))
        else
            skynet.call(exploredb, "lua", "del", k)
        end
    end
    save_list = {}
end

local function queue_save()
    cs(save_info)
end

local function update(roleid, info)
    save_list[roleid] = info
end

local function queue_update(roleid, info)
    cs(update, roleid, info)
end

function CMD.enter(roleid)
    local explore = role_list[roleid]
    if explore then
        return skynet.call(explore, "lua", "enter", roleid)
    end
end

function CMD.explore(roleid, area, fight_point)
    CMD.quit(roleid)
    local explore = assert(explore_area[area], string.format("No explore area %d.", area))
    skynet.call(explore, "lua", "explore", roleid, area, fight_point)
    role_list[roleid] = explore
end

function CMD.quit(roleid)
    local explore = role_list[roleid]
    if explore then
        skynet.call(explore, "lua", "quit", roleid)
    end
end

function CMD.fight(roleid)
    local explore = role_list[roleid]
    if explore then
        skynet.call(explore, "lua", "fight", roleid)
    end
end

function CMD.update(roleid, fight_point)
    local explore = role_list[roleid]
    if explore then
        skynet.call(explore, "lua", "update", roleid, fight_point)
    end
end

function CMD.update_info(roleid, info)
    queue_update(roleid, info)
end

function CMD.shutdown()
    queue_save()
    for k, v in pairs(explore_area) do
        skynet.call(v, "lua", "shutdown")
    end
end

function CMD.routine(key)
    timer.call_routine(key)
end

-- TODO: server shutdown time
function CMD.open()
    local searchdata = sharedata.query("searchdata")
    for k, v in pairs(searchdata) do
        local explore = skynet.newservice("explore")
        skynet.call(explore, "lua", "open", v, skynet.self())
        explore_area[v.area] = explore
    end
    local master = skynet.queryservice("dbmaster")
    exploredb = skynet.call(master, "lua", "get", "exploredb")
    local index = 0
    repeat
        local res = skynet.call(exploredb, "lua", "scan", index)
        index = res[1]
        for k, v in ipairs(res[2]) do
            -- TODO: v is number or string?
            local info = skynet.unpack(skynet.call(exploredb, "lua", "get", v))
            -- TODO: modify start_time and time according to server shutdown time
            local explore = assert(explore_area[info.area], string.format("No explore area %d.", info.area))
            skynet.call(explore, "lua", "add", info)
            role_list[v] = explore
        end
    until index == 0
    timer.add_routine("save_explore", queue_save, 600)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            cs(f, ...)
        else
            skynet.retpack(cs(f, ...))
        end
	end)
end)
