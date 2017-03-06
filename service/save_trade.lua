local skynet = require "skynet"
local timer = require "timer"
local queue = require "skynet.queue"

local ipairs = ipairs
local assert = assert
local string = string

local cs = queue()
local save_list = {}
local tradedb

local CMD = {}

local function save()
    for k, v in pairs(save_list) do
        if v then
            skynet.call(tradedb, "lua", "set", k, skynet.packstring(v))
        else
            skynet.call(tradedb, "lua", "del", k)
        end
    end
    save_list = {}
end

function CMD.update(id, info)
    save_list[id] = info
end

function CMD.batch_update(info, save)
    if save then
        for k, v in ipairs(info) do
            CMD.update(v.id, v)
        end
    else
        for k, v in ipairs(info) do
            CMD.update(v.id, false)
        end
    end
end

function CMD.shutdown()
    save()
    timer.del_routine("save_trade")
end

function CMD.routine(key)
    timer.call_routine(key)
end

skynet.start(function()
    local master = skynet.queryservice("dbmaster")
    tradedb = skynet.call(master, "lua", "get", "tradedb")
    local trade_mgr = skynet.queryservice("trade_mgr")
    local index = 0
    local list = {}
    repeat
        local res = skynet.call(tradedb, "lua", "scan", index)
        index = res[1]
        for k, v in ipairs(res[2]) do
            if not list[v] then
                -- NOTICE: v is string, not number
                local info = skynet.unpack(skynet.call(tradedb, "lua", "get", v))
                skynet.call(trade_mgr, "lua", "add", info)
                list[v] = true
            end
        end
    until index == "0"
    timer.add_routine("save_trade", save, 300)

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            cs(f, ...)
        else
            skynet.retpack(cs(f, ...))
        end
	end)
end)
