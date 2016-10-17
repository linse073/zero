local skynet = require "skynet"

local data
local guild_mgr

local guild = {}
local proc = {}

skynet.init(function()
    guild_mgr = skynet.queryservice("guild_mgr")
end)

function guild.init_module()
    return proc
end

function guild.init(userdata)
    data = userdata
end

function guild.exit()
    data = nil
end

--------------------------protocol process-----------------------

function proc.list_guild(msg)
end

function proc.query_guild(msg)
    local user = data.user
    local r = skynet.call(guild_mgr, "lua", "query", user.id, msg.name)
    return "query_guild_info", {info=r}
end
