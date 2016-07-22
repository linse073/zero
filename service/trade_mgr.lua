local skynet = require "skynet"
local sharedata = require "sharedata"

local assert = assert
local ipairs = ipairs
local pairs = pairs
local string = string

local itemdata

local item_list = {}
local type_list = {}
local role_list = {}

local ITEM_STATUS_NORMAL = 0
local ITEM_STATUS_SELLING = 1
local ITEM_STATUS_SELLED = 2
local ITEM_STATUS_DELETE = 3

local type_key = {
    "quality",
    "needLv",
    "needJob",
}

local CMD = {}

local function check_table(t, k)
    local l = t[k]
    if not l then
        l = {}
        t[k] = l
    end
    return l
end

local function add_count(t, k)
    local c = t[k]
    if c then
        c = c + 1
    else
        c = 1
    end
end

function CMD.add(info, data)
    assert(not item_list[info.id], string.format("Already has item %d.", info.id))
    assert(info.owner~=0, "Error trade item owner.")
    assert(info.status==ITEM_STATUS_SELLING, "Error trade item status.")
    if not data then
        data = assert(itemdata[info.itemid], string.format("No item data %d.", info.itemid))
    end
    local i = {info, data}
    item_list[info.id] = i
    check_table(role_list, info.owner)[info.id] = i
    local t = check_table(type_list, data.itemType)
    check_table(t, "all")[info.id] = i
    for k, v in ipairs(type_key) do
        local l = check_table(check_table(t, k), data[v])
        check_table(l, 1)[info.id] = i
        add_count(l, 2)
    end
end

function CMD.role_item(id)
    return role_list[id]
end

function CMD.del(id)
    local i = item_list[id]
    if i then
        local info = i[1]
        local data = i[2]
        item_list[info.id] = nil
        role_list[info.owner][info.id] = nil
        local t = type_list[data.itemType]
        t.all[info.id] = nil
        for k, v in ipairs(type_key) do
            local l = t[k][data[v]]
            l[1][info.id] = nil
            l[2] = l[2] + 1
        end
    end
end

function CMD.query(it, quality, level, prof)
    local p = {}
    local t = type_list[it]
    if t then
        local key = {quality, level, prof}
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
