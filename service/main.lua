local skynet = require "skynet"
local util = require "util"

local string = string
local ipairs = ipairs
local floor = math.floor
local tonumber = tonumber

skynet.start(function()
	skynet.error("Server start")

    local t = util.parse_time(skynet.getenv("start_time"))
    skynet.setenv("start_utc_time", t)
    skynet.setenv("start_routine_time", util.day_time(t))

    -- debug service
    if not skynet.getenv("daemon") then
        skynet.newservice("console")
    end
	skynet.newservice("debug_console", skynet.getenv("debug_console"))

    -- service
    local master = skynet.uniqueservice("dbmaster")
    local config = require(skynet.getenv("config"))
    for k, v in ipairs(config.db) do
        local dbslave = skynet.newservice("dbslave")
        skynet.call(dbslave, "lua", "open", v)
    end
    local statusdb = skynet.call(master, "lua", "get", "statusdb")
    local open_time = skynet.call(statusdb, "lua", "get", "open_time")
    local now = floor(skynet.time())
    if open_time then
        open_time = tonumber(open_time)
    else
        open_time = now
    end
    skynet.call(statusdb, "lua", "save", "last_open_time", open_time)
    skynet.setenv("last_open_time", open_time)
    skynet.setenv("open_time", now)
    local shutdown_time = skynet.call(statusdb, "lua", "get", "shutdown_time")
    if shutdown_time then
        shutdown_time = tonumber(shutdown_time)
    else
        shutdown_time = now
    end
    skynet.setenv("shutdown_time", shutdown_time)

	skynet.uniqueservice("cache")
    skynet.uniqueservice("server_mgr")
    skynet.uniqueservice("routine")
    skynet.uniqueservice("role_mgr")
    skynet.uniqueservice("arena_rank")
    skynet.uniqueservice("fight_point_rank")
    skynet.uniqueservice("rank_mgr")
    skynet.uniqueservice("offline_mgr")
    skynet.uniqueservice("task_rank")
    local save_explore = skynet.uniqueservice("save_explore")
    skynet.uniqueservice("explore_mgr")
    -- TODO: server shutdown time
    skynet.call(save_explore, "lua", "open")
    skynet.uniqueservice("trade_mgr")
    skynet.uniqueservice("save_trade")

	local loginserver = skynet.newservice("logind")
    local gate = skynet.newservice("gated", loginserver)
    skynet.call(gate, "lua", "open", config.gate)
    for k, v in ipairs(config.server) do
        local server = skynet.newservice("server", loginserver)
        skynet.call(server, "lua", "open", v, config.gate.servername)
    end
    skynet.uniqueservice("guild_mgr")
    skynet.uniqueservice("agent_mgr")
    
    skynet.exit()
end)
