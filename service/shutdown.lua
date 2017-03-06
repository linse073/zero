local skynet = require "skynet"

local floor = math.floor

skynet.start(function()
    local server_mgr = skynet.queryservice("server_mgr")
    skynet.call(server_mgr, "lua", "shutdown")
    local explore_mgr = skynet.queryservice("explore_mgr")
    skynet.call(explore_mgr, "lua", "shutdown")
    local save_explore = skynet.queryservice("save_explore")
    skynet.call(save_explore, "lua", "shutdown")
    local save_trade = skynet.queryservice("save_trade")
    skynet.call(save_trade, "lua", "shutdown")
    local task_rank = skynet.queryservice("task_rank")
    skynet.call(task_rank, "lua", "shutdown")
    local guild_mgr = skynet.queryservice("guild_mgr")
    skynet.call(guild_mgr, "lua", "shutdonw")
    local master = skynet.queryservice("dbmaster")
    local statusdb = skynet.call(master, "lua", "get", "statusdb")
    skynet.call(statusdb, "lua", "set", "shutdown_time", floor(skynet.time()))
    -- TODO: save server shutdown time
    skynet.error("shutdown finish.")
    skynet.exit()
end)
