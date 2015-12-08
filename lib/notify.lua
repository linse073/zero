local skynet = require "skynet"
local share = require "share"

local error = error
local assert = assert
local ipairs = ipairs
local coroutine = coroutine
local string = string

local error_code
local name_msg
local sproto

local notify = {}

local notify_queue = {}
local notify_coroutine

skynet.init(function()
    error_code = share.error_code
    name_msg = share.name_msg
    sproto = share.sproto
end)

local function pack()
    local content = ""
    for k, v in ipairs(notify_queue) do
        local m, c = v[1], v[2]
        if sproto:exist_type(m) then
            c = sproto:pencode(m, c)
        end
        local id = assert(name_msg[m], string.format("No protocol %s.", m))
        c = string.pack(">s2", string.pack(">I2", id) .. c)
        content = content .. c
    end
    notify_queue = {}
    return "notify_info", content
end

function notify.send()
    if notify_coroutine then
        error({code = error_code.ALREADY_NOTIFY})
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
        notify.add("logout", "")
    end
end

return notify
