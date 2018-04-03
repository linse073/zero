local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local cjson = require "cjson"
local md5 = require "md5"

local table = table
local string = string
local ipairs = ipairs
local tonumber = tonumber

local web_sign = skynet.getenv("web_sign")

local mode = ...

if mode == "agent" then
    local offline_mgr
    local role_mgr

    skynet.init(function()
        offline_mgr = skynet.queryservice("offline_mgr")
        role_mgr = skynet.queryservice("role_mgr")
    end)

    local process = {
        -- query = {{"id", "time"}, function(q)
        --     local id = tonumber(q.id)
        --     local info = skynet.call(role_mgr, "lua", "get_user", id)
        --     if info then
        --         return {
        --             account = info.account,
        --             nick_name = info.nick_name,
        --             head_img = info.head_img,
        --             room_card = info.room_card,
        --         }
        --     else
        --         return {error="no player"}
        --     end
        -- end},
        -- add_card = {{"id", "card", "time"}, function(q)
        --     local id = tonumber(q.id)
        --     local info = skynet.call(role_mgr, "lua", "get_info", id)
        --     if info then
        --         skynet.call(offline_mgr, "lua", "add", id, "role", "add_room_card", tonumber(q.card))
        --         return {ret="OK"}
        --     else
        --         return {error="no player"}
        --     end
        -- end},
        -- charge = {{"id", "tradeNO", "cashFee", "retCode", "retMsg", "time"}, function(q)
        --     local id = tonumber(q.id)
        --     local info = skynet.call(role_mgr, "lua", "get_info", id)
        --     if info then
        --         skynet.call(offline_mgr, "lua", "add", id, "role", "charge", q)
        --         return {ret="OK"}
        --     else
        --         return {error="no player"}
        --     end
        -- end},
        -- unlink = {{"id", "time"}, function(q)
        --     local id = tonumber(q.id)
        --     local info = skynet.call(role_mgr, "lua", "get_info", id)
        --     if info then
        --         skynet.call(offline_mgr, "lua", "add", id, "role", "unlink")
        --         return {ret="OK"}
        --     else
        --         return {error="no player"}
        --     end
        -- end},
    }

    local function response(id, ...)
        local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
        if not ok then
            -- if err == sockethelper.socket_error , that means socket closed.
            skynet.error(string.format("fd = %d, %s", id, err))
        end
    end
    skynet.start(function()
        skynet.dispatch("lua", function (_, _, id)
            socket.start(id)
            -- limit request body size to 8192 (you can pass nil to unlimit)
            local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
            if code then
                if code ~= 200 then
                    response(id, code)
                else
                    local path, query = urllib.parse(url)
                    local resp = ""
                    if path and query then
                        local func = path:match("([^/]*)$")
                        local q = urllib.parse_query(query)
                        local p = process[func]
                        if p then
                            local s = ""
                            local ret
                            for k, v in ipairs(p[1]) do
                                local a = q[v]
                                if a then
                                    s = s .. a .. "&"
                                else
                                    ret = {error="error parameter"}
                                    break
                                end
                            end
                            if not ret then
                                s = s .. web_sign
                                local sign = md5.sumhexa(s)
                                if sign ~= q.sign then
                                    ret = {error="error sign"}
                                else
                                    ret = p[2](q)
                                end
                            end
                            resp = cjson.encode(ret)
                        end
                    end
                    response(id, code, resp)
                end
            else
                if url == sockethelper.socket_error then
                    skynet.error("socket closed")
                else
                    skynet.error(url)
                end
            end
            socket.close(id)
        end)
    end)
else
    skynet.start(function()
        local agent = {}
        for i = 1, 20 do
            agent[i] = skynet.newservice(SERVICE_NAME, "agent")
        end
        local balance = 1
        local port = tonumber(mode)
        local id = socket.listen("0.0.0.0", port)
        skynet.error(string.format("Listen web port %d", port))
        socket.start(id , function(id, addr)
            skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
            skynet.send(agent[balance], "lua", id)
            balance = balance + 1
            if balance > #agent then
                balance = 1
            end
        end)
    end)
end
