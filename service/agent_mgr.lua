local skynet = require "skynet"

local assert = assert
local pcall = pcall
local string = string
local ipairs = ipairs

local free_list = {}
local agent_list = {}

local function new_agent(num)
    local t = {}
    for i = 1, num do
        t[i] = skynet.newservice("agent") 
    end
    local l = #free_list
    for k, v in ipairs(t) do
        l = l + 1
        free_list[l] = v
        agent_list[v] = l
    end
end

local function del_agent(num)
    local l = #free_list
    if num > l then
        num = l
    end
    local t = {}
    for i = 1, num do
        local agent = free_list[l]
        t[i] = agent
        free_list[l] = nil
        agent_list[agent] = nil
        l = l - 1
    end
    for k, v in ipairs(t) do
        -- NOTICE: logout may call skynet.exit, so you should use pcall.
        pcall(skynet.call, v, "lua", "exit")
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
        if l <= 10 then
            skynet.fork(new_agent, 10)
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
        if l >= 150 then
            skynet.fork(del_agent, 50)
        end
    end
end

skynet.start(function()
    new_agent(100)

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        skynet.retpack(f(...))
	end)
end)
