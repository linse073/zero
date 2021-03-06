local skynet = require "skynet"
local share = require "share"
local notify = require "notify"
local util = require "util"

local role

local update_user = util.update_user
local error_code
local data
local guild_mgr
local explore_mgr
local role_mgr
local cz

local guild = {}
local proc = {}

skynet.init(function()
    error_code = share.error_code
    cz = share.cz
    guild_mgr = skynet.queryservice("guild_mgr")
    explore_mgr = skynet.queryservice("explore_mgr")
    role_mgr = skynet.queryservice("role_mgr")
end)

function guild.init_module()
    role = require "game.role"
    return proc
end

function guild.init(userdata)
    data = userdata
end

function guild.exit()
    data = nil
end

function guild.notify(i)
    if i then
        data.guild = i[1]
        data.guildid = i[2]
        local info = skynet.call(i[1], "lua", "pack_info")
        notify.add("update_user", {update={guild=info}})
    else
        data.guild = nil
        data.guildid = nil
        notify.add("update_user", {quit_guild=true})
    end
end

--------------------------protocol process-----------------------

function proc.list_guild(msg)
    local user = data.user
    if not msg.page then
        error{code = error_code.ERROR_ARGS}
    end
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
    if user.level < 15 then
        error{code = error_code.ROLE_LEVEL_LIMIT}
    end
    if data.guild then
        error{code = error_code.ALREADY_HAS_GUILD}
    end
    local r, g, id = skynet.call(guild_mgr, "lua", "apply", user.id, msg.id, user.level, user.vip)
    if r ~= error_code.OK then
        error{code = r}
    end
    if id then
        data.guild = g
        data.guildid = id
        local info = skynet.call(g, "lua", "pack_info")
        return "update_user", {update={guild=info}}
    else
        return "guild_rank_info", g
    end
end

function proc.found_guild(msg)
    local user = data.user
    if user.level < 20 then
        error{code = error_code.ROLE_LEVEL_LIMIT}
    end
    if data.guild then
        error{code = error_code.ALREADY_HAS_GUILD}
    end
    local p = update_user()
    cz.start()
    if user.rmb < 500 then
        error{code = error_code.ROLE_RMB_LIMIT}
    end
    local r, g, id = skynet.call(guild_mgr, "lua", "found", user.id, data.server, msg.name)
    if r ~= error_code.OK then
        error{code = r}
    end
    role.add_rmb(p, -500)
    cz.finish()
    data.guild = g
    data.guildid = id
    p.guild = skynet.call(g, "lua", "pack_info")
    return "update_user", {update=p}
end

function proc.dismiss_guild(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r = skynet.call(guild_mgr, "lua", "dismiss", user.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    data.guild = nil
    data.guildid = nil
    return "update_user", {dismiss_guild=true}
end

function proc.guild_notice(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r, update = skynet.call(data.guild, "lua", "config", user.id, "notice", msg.notice)
    if r ~= error_code.OK then
        error{code = r}
    end
    return "update_user", {update={guild={info=update}}}
end

function proc.guild_icon(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r, update = skynet.call(data.guild, "lua", "config", user.id, "icon", msg.icon)
    if r ~= error_code.OK then
        error{code = r}
    end
    skynet.call(guild_mgr, "lua", "update", data.guildid, "icon", msg.icon)
    local occupy_area = skynet.call(explore_mgr, "lua", "occupy_area", data.guildid)
    if occupy_area and not util.empty(occupy_area) then
        local gi = skynet.call(guild_mgr, "lua", "simple_info", data.guildid)
        local ag = {}
        for k, v in pairs(occupy_area) do
            ag[#ag+1] = {
                area = k,
                info = gi,
            }
        end
        skynet.call(role_mgr, "lua", "broadcast", "update_user", {update={area_guild=ag}})
    end
    return "update_user", {update={guild={info=update}}}
end

function proc.guild_apply_level(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r, update = skynet.call(data.guild, "lua", "config", user.id, "apply_level", msg.apply_level)
    if r ~= error_code.OK then
        error{code = r}
    end
    skynet.call(guild_mgr, "lua", "update", data.guildid, "apply_level", msg.apply_level)
    return "update_user", {update={guild={info=update}}}
end

function proc.guild_apply_vip(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r, update = skynet.call(data.guild, "lua", "config", user.id, "apply_vip", msg.apply_vip)
    if r ~= error_code.OK then
        error{code = r}
    end
    skynet.call(guild_mgr, "lua", "update", data.guildid, "apply_vip", msg.apply_vip)
    return "update_user", {update={guild={info=update}}}
end

function proc.accept_apply(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r, update = skynet.call(guild_mgr, "lua", "accept", user.id, msg.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    return "update_user", {update={guild=update}}
end

function proc.accept_all_apply(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r, update = skynet.call(guild_mgr, "lua", "accept_all", user.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    return "update_user", {update={guild=update}}
end

function proc.refuse_apply(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r = skynet.call(guild_mgr, "lua", "refuse", user.id, msg.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    return "refuse_apply", {id=msg.id}
end

function proc.refuse_all_apply(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r = skynet.call(guild_mgr, "lua", "refuse_all", user.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    return "refuse_all_apply", ""
end

function proc.guild_expel(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r, update = skynet.call(guild_mgr, "lua", "expel", user.id, msg.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    return "update_user", {update={guild=update}}
end

function proc.guild_promote(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r, update = skynet.call(data.guild, "lua", "promote", user.id, msg.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    return "update_user", {update={guild=update}}
end

function proc.guild_demote(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r, update = skynet.call(data.guild, "lua", "demote", user.id, msg.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    return "update_user", {update={guild=update}}
end

function proc.guild_demise(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    if user.id == msg.id then
        error{code = error_code.ERROR_ARGS}
    end
    local r, update = skynet.call(data.guild, "lua", "demise", user.id, msg.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    return "update_user", {update={guild=update}}
end

function proc.quit_guild(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r = skynet.call(guild_mgr, "lua", "quit", user.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    data.guild = nil
    data.guildid = nil
    return "update_user", {quit_guild=true}
end

function proc.get_apply(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local r, a = skynet.call(data.guild, "lua", "get_apply", user.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    return "apply_info", {info=a}
end

function proc.upgrade_guild_skill(msg)
    if not data.guild then
        error{code = error_code.NOT_JOIN_GUILD}
    end
    local user = data.user
    local p = update_user()
    cz.start()
    local r, update, contribute, rmb, count_limit = skynet.call(data.guild, "lua", "upgrade_skill", user.id, msg.rmb, user.rmb, msg.id)
    if r ~= error_code.OK then
        error{code = r}
    end
    if rmb then
        role.add_rmb(p, -rmb)
    end
    cz.finish()
    role.add_contribute(p, contribute)
    if count_limit then
        skynet.call(guild_mgr, "lua", "update", data.guildid, "count_limit", count_limit)
    end
    p.guild = update
    return "update_user", {update=p}
end

return guild
