local skynet = require "skynet"
local util = require "util"

local string = string
local ipairs = ipairs
local tonumber = tonumber
local os = os

skynet.start(function()
	skynet.error("Server start")

    local year, month, day, hour, min, sec = string.match(skynet.getenv("start_time"), "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    local st = {
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec),
    }
    local t = os.time(st)
    skynet.setenv("start_utc_time", t)
    skynet.setenv("start_routine_time", util.day_time(t))

    -- debug service
    if not skynet.getenv("daemon") then
        skynet.newservice("console")
    end
	skynet.newservice("debug_console", skynet.getenv("debug_console"))

    -- service
    local config = require(skynet.getenv("config"))
    for k, v in ipairs(config.db) do
        local dbslave = skynet.newservice("dbslave")
        skynet.call(dbslave, "lua", "open", v)
    end

	skynet.uniqueservice("cache")
    skynet.uniqueservice("dbmaster")
    skynet.uniqueservice("server_mgr")
    skynet.uniqueservice("routine")
    local rolemgr = skynet.uniqueservice("role_mgr")
    local arenarank = skynet.uniqueservice("arena_rank")
    local fightpointrank = skynet.uniqueservice("fight_point_rank")
    skynet.uniqueservice("agent_mgr")
    local exploremgr = skynet.uniqueservice("explore_mgr")

    skynet.call(rolemgr, "lua", "open")
    skynet.call(arenarank, "lua", "open")
    skynet.call(fightpointrank, "lua", "open")
    skynet.call(exploremgr, "lua", "open")
	local loginserver = skynet.newservice("logind")
    local gate = skynet.newservice("gated", loginserver)
    skynet.call(gate, "lua", "open", config.gate)
    for k, v in ipairs(config.server) do
        local server = skynet.newservice("server", loginserver)
        skynet.call(server, "lua", "open", v, config.gate.servername)
    end
    
    skynet.exit()
end)
