local skynet = require "skynet"
local util = require "util"

local dump = util.dump
local print = print
local tonumber = tonumber
local select = select
local pcall = pcall
local type = type
local string = string
local table = table
local floor = math.floor

local arg = {...}

local CMD = {}

function CMD.add_mail(id, mtype, title, content)
    id = tonumber(id)
    mtype = tonumber(mtype)
    local m = {
        type = mtype,
        time = floor(skynet.time()),
        title = title,
        content = content,
        item_award = {
            {itemid=3000000091, num=2},
        },
    }
    local mail_mgr = skynet.queryservice("mail_mgr")
    skynet.call(mail_mgr, "lua", "send", id, m)
end

function CMD.broadcast_mail(mtype, title, content)
    mtype = tonumber(mtype)
    local m = {
        type = mtype,
        time = floor(skynet.time()),
        title = title,
        content = content,
        item_award = {
            {itemid=3000000091, num=2},
        },
    }
    local mail_mgr = skynet.queryservice("mail_mgr")
    skynet.call(mail_mgr, "lua", "broadcast", m)
end

skynet.start(function()
	local command = arg[1]
	local c = CMD[command]
	local ok, list
	if c then
		ok, list = pcall(c, select(2, table.unpack(arg)))
	else
        print(string.format("Invalid command %s.", command))
	end
	if ok then
		if list then
			if type(list) == "string" then
				print(list)
			else
                dump(list)
			end
		end
        print("OK")
	else
		print("Error:", list)
	end

    skynet.exit()
end)
