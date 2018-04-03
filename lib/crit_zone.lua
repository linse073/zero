local skynet = require "skynet"
local coroutine = coroutine
local table = table
local getinfo = debug.getinfo
local assert = assert

local function crit_zone()
    local current_thread
    local thread_queue = {}
    local call_queue = {}
    local call_index = 0

    local cmd = {}

    function cmd.start(level)
        local thread = coroutine.running()
        if current_thread and current_thread ~= thread then
            table.insert(thread_queue, thread)
            skynet.wait()
            assert(call_index == 0 and #call_queue == 0) -- current_thread == thread
        end
        current_thread = thread
        call_index = call_index + 1
        call_queue[call_index] = getinfo(level or 2, "f").func
    end

    function cmd.finish(level)
        local func = getinfo(level or 2, "f").func
        while call_index > 0 do
            if call_queue[call_index] == func then
                break
            end
            call_index = call_index - 1
        end
        assert(call_index > 0)
        call_index = call_index - 1
        if call_index == 0 then
            call_queue = {}
            current_thread = table.remove(thread_queue, 1)
            if current_thread then
                skynet.wakeup(current_thread)
            end
        end
    end

    function cmd.over()
        local thread = coroutine.running()
        if current_thread == thread then
            call_index = 0
            call_queue = {}
            current_thread = table.remove(thread_queue, 1)
            if current_thread then
                skynet.wakeup(current_thread)
            end
        end
    end

    local function ret(...)
        cmd.finish(4)
        return ...
    end
    function cmd.call(f, ...)
        cmd.start(3)
        return ret(f(...))
    end

    return cmd
end

return crit_zone
