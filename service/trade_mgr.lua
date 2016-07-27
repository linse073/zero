local skynet = require "skynet"
local sharedata = require "sharedata"

local assert = assert
local ipairs = ipairs
local pairs = pairs
local string = string

local itemdata

local item_list = {}
local role_list = {}
local type_list = {}

local CMD = {}

local function check_table(t, k)
    local l = t[k]
    if not l then
        l = {}
        t[k] = l
    end
    return l
end

function CMD.add(info, data)
    assert(not item_list[info.id], string.format("Already has item %d.", info.id))
    if not data then
        data = assert(itemdata[info.itemid], string.format("No item data %d.", info.itemid))
    end
    local i = {info, data}
    item_list[info.id] = i
    check_table(role_list, info.owner)[info.id] = i
    local t = check_table(type_list, info.itemid)
    check_table(t, 1)[info.id] = i
    if data.overlay > 1 then
        local p = check_table(check_table(t, 2), info.price)
        check_table(p, 1)[info.id] = i
        p[2] = (p[2] or 0) + info.num
    end
end

function CMD.get(id)
    return item_list[id]
end

function CMD.role_item(id)
    local p = {}
    local l = role_list[id]
    if l then
        for k, v in pairs(l) do
            p[#p+1] = v[1]
        end
    end
    return p
end

function CMD.del(id)
    local i = item_list[id]
    if i then
        local info = i[1]
        local data = i[2]
        item_list[info.id] = nil
        role_list[info.owner][info.id] = nil
        local t = type_list[data.itemid]
        t[1][info.id] = nil
        local p = t[2][info.price]
        p[1][info.id] = nil
        p[2] = p[2] - info.num
        return true
    end
end

function CMD.query(id)
    local p = {}
    local t = type_list[id]
    if t then
        local l = t[2]
        if l then
        else
        end
    end
    return p
end

function CMD.query(con)
    local p = {}
    local t = type_list[con.type]
    if t then
        local key = {con.quality, con.level, con.prof}
        local a = t.all
        local c
        local has = false
        for k, v in ipairs(type_key) do
            local kv = key[k]
            if kv then
                has = true
                local l = t[k][kv]
                if l then
                    local lc = l[2]
                    if not c or lc < c then
                        a = l[1]
                        c = lc
                    end
                else
                    a = nil
                    break
                end
            end
        end
        if a then
            if has then
                for k, v in pairs(a) do
                    local m = true
                    for k1, v1 in ipairs(type_key) do
                        local kv = key[k1]
                        if kv and kv ~= v[2][v1] then
                            m = false
                            break
                        end
                    end
                    if m then
                        p[#p+1] = v[1]
                    end
                end
            else
                for k, v in pairs(a) do
                    p[#p+1] = v[1]
                end
            end
        end
    end
    return p
end

skynet.start(function()
    itemdata = sharedata.query("itemdata")

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            f(...)
        else
            skynet.retpack(f(...))
        end
	end)
end)
