local skynet = require "skynet"
local share = require "share"

local error = error
local assert = assert
local ipairs = ipairs
local coroutine = coroutine
local string = string
local error_code = share.error_code
local name_msg = share.name_msg
local sproto = share.sproto

local notify = {}

local notify_queue = {}
local notify_coroutine

local function pack()
    local l = #notify_queue
    if l > 0 then
        local content = ""
        for k, v in ipairs(notify_queue) do
            local c = sproto:pencode(v[1], v[2])
            local id = assert(name_msg[v[1]], string.format("No protocol %s.", v[1]))
            c = string.pack(">s2", string.pack(">I2", id) .. c)
            content = content .. c
        end
        notify_queue = {}
        return "notofy_info", content
    else
        return "nope", ""
    end
end

function notify.send()
    if notify_coroutine then
        error(error_code.ALREADY_NOTIFY)
    end
    if #notify_queue == 0 then
        notify_coroutine = coroutine.running()
        skynet.wait(notify_coroutine)
    end
    notify_coroutine = nil
    return pack()
end

function notify.add(msg, content)
    notify_queue[#notify_queue+1] = {msg, content}
    if notify_coroutine then
        skynet.wakeup(notify_coroutine)
    end
end

function notify.exit()
    if notify_coroutine then
        skynet.wakeup(notify_coroutine)
    end
end

return notify
