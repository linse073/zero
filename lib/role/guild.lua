local skynet = require "skynet"
local share = require "share"
local notify = require "notify"

local error_code
local data
local guild_mgr

local guild = {}
local proc = {}

skynet.init(function()
    error_code = share.error_code
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

function guild.join(i)
    data.guild = i[1]
    data.guildid = i[2]
    local info = skynet.call(g, "lua", "pack_info")
    notify.add("update_user", {update={guild=info}})
end

--------------------------protocol process-----------------------

function proc.list_guild(msg)
    local user = data.user
    local r, l = skynet.call(guild_mgr, "lua", "list", user.id, msg.page)
    return "list_guild_info", {info=r, page=msg.page, total=l}
end

function proc.query_guild(msg)
    local user = data.user
    local r = skynet.call(guild_mgr, "lua", "query", user.id, msg.name)
    return "query_guild_info", {info=r}
end

function proc.query_apply(msg)
    if data.guild then
        error{code = error_code.ALREADY_HAS_GUILD}
    end
    local user = data.user
    local r = skynet.call(guild_mgr, "lua", "query_apply", user.id)
    return "query_apply_info", {info=r}
end

function proc.apply_guild(msg)
    local user = data.user
    if user.level < 20 then
        error{code = error_code.ROLE_LEVEL_LIMIT}
    end
    if data.guild then
        error{code = error_code.ALREADY_HAS_GUILD}
    end
    local r, g, id = skynet.call(guild_mgr, "lua", "apply", user.id, msg.id, user.level, user.vip)
    if r ~= error_code.OK then
        error{code = r}
    end
    if g then
        data.guild = g
        data.guildid = id
        local info = skynet.call(g, "lua", "pack_info")
        return "update_user", {update={guild=info}}
    else
        return "apply_guild", {id=msg.id}
    end
end

function proc.found_guild(msg)
    local user = data.user
    if user.level < 30 then
        error{code = error_code.ROLE_LEVEL_LIMIT}
    end
    if data.guild then
        error{code = error_code.ALREADY_HAS_GUILD}
    end
    local r, g, id = skynet.call(guild_mgr, "lua", "found", user.id, data.server, msg.name)
    if r ~= error_code.OK then
        error{code = r}
    end
    data.guild = g
    data.guildid = id
    local info = skynet.call(g, "lua", "pack_info")
    return "update_user", {update={guild=info}}
end

function proc.dismiss_guild(msg)
    if not data.guild then
        error_code{code = error_code.NOT_JOIN_GUILD}
    end
    local r = skynet.call(guild_mgr, "lua", "dismiss", user.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    data.guild = nil
    data.guildid = nil
    return "update_user", {dismiss_guild=true}
end

return guild
