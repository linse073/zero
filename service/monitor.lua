local skynet = require "skynet"
local socket = require "socket"

local pcall = pcall
local select = select
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local type = type
local table = table
local string = string

local port = tonumber(...)
local COMMAND = {}

local function format_table(t)
	local index = {}
	for k in pairs(t) do
		table.insert(index, k)
	end
	table.sort(index)
	local result = {}
	for _, v in ipairs(index) do
		table.insert(result, string.format("%s:%s", v, tostring(t[v])))
	end
	return table.concat(result, "\t")
end

local function dump_line(print, key, value)
	if type(value) == "table" then
		print(key, format_table(value))
	else
		print(key, tostring(value))
	end
end

local function dump_list(print, list)
	local index = {}
	for k in pairs(list) do
		table.insert(index, k)
	end
	table.sort(index)
	for _, v in ipairs(index) do
		dump_line(print, v, list[v])
	end
	print("OK")
end

local function split_cmdline(cmdline)
	local split = {}
	for i in string.gmatch(cmdline, "%S+") do
		table.insert(split, i)
	end
	return split
end

local function docmd(cmdline, print, fd)
	local split = split_cmdline(cmdline)
	local command = split[1]
	local cmd = COMMAND[command]
	local ok, list
	if cmd then
		ok, list = pcall(cmd, select(2, table.unpack(split)))
	else
		print(string.format("Invalid command %s.", command))
	end

	if ok then
		if list then
			if type(list) == "string" then
				print(list)
			else
				dump_list(print, list)
			end
		else
			print("OK")
		end
	else
		print("Error:", list)
	end
end

local function console_main_loop(stdin, print)
	socket.lock(stdin)
	print("Welcome to server monitor")
	while true do
		local cmdline = socket.readline(stdin, "\n")
		if not cmdline then
			break
		end
		if cmdline ~= "" then
			docmd(cmdline, print, stdin)
		end
	end
	socket.unlock(stdin)
end

skynet.start(function()
	local listen_socket = socket.listen ("127.0.0.1", port)
	skynet.error("Start server monitor at 127.0.0.1 " .. port)
	socket.start(listen_socket, function(id, addr)
		local function print(...)
			local t = { ... }
			for k, v in ipairs(t) do
				t[k] = tostring(v)
			end
			socket.write(id, table.concat(t, "\t"))
			socket.write(id, "\n")
		end
		socket.start(id)
		skynet.fork(console_main_loop, id, print)
	end)
end)

function COMMAND.shutdown()
    pcall(skynet.call(skynet.queryservice("agent_mgr"), "lua", "exit"))
    skynet.exit()
end
