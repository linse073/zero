local skynet = require "skynet"

local assert = assert
local pcall = pcall
local string = string

local free_list = {}
local agent_list = {}
local fork_new = false
local fork_del = false

local function new_agent(num)
    local l = #free_list + 1
    for i = 1, num do
        local agent = skynet.newservice("agent") 
        free_list[l] = agent
        agent_list[agent] = l
        l = l + 1
    end
    fork_new = false
end

local function del_agent(num)
    local l = #free_list
    assert(num < l, string.format("Delete agent error %d, free agent %d.", num, l))
    local t = {}
    for i = 1, num do
        local agent = free_list[l]
        t[i] = agent
        free_list[l] = nil
        agent_list[agent] = nil
        l = l - 1
    end
    fork_del = false
    for k, v in ipairs(t) do
        -- NOTICE: logout may call skynet.exit, so you should use pcall.
        pcall(skynet.call, v, "lua", "exit", false)
    end
end

local CMD = {}

function CMD.get()
    local l = #free_list
    local agent
    if l > 0 then
        agent = free_list[l]
        free_list[l] = nil
        agent_list[agent] = 0
        if not fork_new and l <= 10 then
            skynet.fork(new_agent, 10)
            fork_new = true
        end
    else
        agent = skynet.newservice("agent")
        agent_list[agent] = 0
    end
    return agent
end

function CMD.free(agent)
    if agent_list[agent] == 0 then
        local l = #free_list + 1
        free_list[l] = agent
        agent_list[agent] = l
        if not fork_del and l >= 150 then
            skynet.fork(del_agent, 50)
            fork_del = true
        end
    end
end

function CMD.exit()
    for k, v in pairs(agent_list) do
        pcall(skynet.call, v, "lua", "exit", true)
    end
    skynet.exit()
end

skynet.start(function()
    new_agent(100)

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
