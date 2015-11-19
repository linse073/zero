local skynet = require "skynet"

local assert = assert
local pcall = pcall
local string = string

local free_list = {}

local function new_agent(num)
    local l = #free_list + 1
    for i = 1, num do
        free_list[l] = skynet.newservice("agent")
        l = l + 1
    end
end

local function del_agent(num)
    local l = #free_list
    assert(num < l, string.format("Delete agent %d exceed max free agent %d.", num, l))
    local t = {}
    for i = 1, num do
        t[i], free_list[l] = free_list[l], nil
        l = l - 1
    end
    for k, v in ipairs(t) do
        -- NOTICE: logout may call skynet.exit, so you should use pcall.
        pcall(skynet.call, v, "lua", "exit")
    end
end

function init()
    new_agent(100)
end

function exit()
    
end

function response.get_agent()
    local l = #free_list
    local agent = free_list[l]
    free_list[l] = nil
    if l - 1 < 10 then
        skynet.fork(new_agent, 10)
    end
    return agent
end

function response.free_agent(agent)
    local l = #free_list + 1
    free_list[l] = agent
    if l >= 100 then
        skynet.fork(del_agent, 50)
    end
end
