local skynet = require "skynet"
local timer = require "timer"
local queue = require "skynet.queue"

local ipairs = ipairs
local assert = assert
local string = string

local cs = queue()
local save_list = {}
local exploredb

local CMD = {}

local function save()
    for k, v in pairs(save_list) do
        if v then
            skynet.call(exploredb, "lua", "set", k, skynet.packstring(v))
        else
            skynet.call(exploredb, "lua", "del", k)
        end
    end
    save_list = {}
end

function CMD.update(roleid, info)
    save_list[roleid] = info
end

function CMD.shutdown()
    save()
    timer.del_routine("save_explore")
end

function CMD.routine(key)
    timer.call_routine(key)
end

-- TODO: server shutdown time
function CMD.open()
    local master = skynet.queryservice("dbmaster")
    exploredb = skynet.call(master, "lua", "get", "exploredb")
    local explore_mgr = skynet.queryservice("explore_mgr")
    local index = 0
    local list = {}
    repeat
        local res = skynet.call(exploredb, "lua", "scan", index)
        index = res[1]
        for k, v in ipairs(res[2]) do
            if not list[v] then
                -- NOTICE: v is string, not number
                local info = skynet.unpack(skynet.call(exploredb, "lua", "get", v))
                -- TODO: modify start_time and time according to server shutdown time
                local explore = skynet.call(explore_mgr, "lua", "get_explore", info.area)
                skynet.call(explore, "lua", "add", info)
                list[v] = true
            end
        end
    until index == "0"
    timer.add_routine("save_explore", save, 600)
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
