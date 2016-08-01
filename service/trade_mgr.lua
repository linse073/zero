local skynet = require "skynet"
local sharedata = require "sharedata"

local assert = assert
local ipairs = ipairs
local pairs = pairs
local string = string
local table = table

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

function CMD.batch_add(info, data)
    for k, v in ipairs(info) do
        CMD.add(v, data)
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

function CMD.del(id, num)
    local i = item_list[id]
    if i then
        local info = i[1]
        local data = i[2]
        if num and info.num > num then
            info.num = info.num - num
            if data.overlay > 1 then
                local t = type_list[info.itemid]
                local p = t[2][info.price]
                p[2] = p[2] - num
            end
            return num, info
        else
            item_list[info.id] = nil
            role_list[info.owner][info.id] = nil
            local t = type_list[info.itemid]
            t[1][info.id] = nil
            if data.overlay > 1 then
                local p = t[2][info.price]
                p[1][info.id] = nil
                p[2] = p[2] - info.num
            end
            return info.num
        end
    end
    return 0
end

local function sort(l, r)
    return l.status_time < r.status_time
end
function CMD.del_by_itemid(id, price, num)
    local t = type_list[id]
    if t then
        local p = t[2][price]
        if p then
            local l = {}
            for k, v in pairs(p[1]) do
                l[#l+1] = v[1]
            end
            table.sort(l, sort)
            local tn = 0
            local del = {}
            local ln, u
            for k, v in ipairs(l) do
                ln, u = CMD.del(v.id, num)
                tn = tn + ln
                del[#del+1] = v
                num = num - ln
                if num == 0 then
                    break
                end
            end
            if u then
                del[#del] = nil
            end
            return tn, del, ln, u
        end
    end
    return 0
end

function CMD.del_by_role(id, roleid, price)
    local p = {}
    local l = role_list[roleid]
    if l then
        for k, v in pairs(l) do
            local s = v[1]
            if s.itemid == id and s.price == price then
                p[#p+1] = s
            end
        end
        for k, v in ipairs(p) do
            CMD.del(v.id)
        end
    end
    return p
end

function CMD.query(id)
    local p = {}
    local t = type_list[id]
    if t then
        local l = t[2]
        if l then
            for k, v in pairs(l) do
                local num = v[2]
                if num > 0 then
                    p[#p+1] = {
                        itemid = id,
                        price = k,
                        num = num,
                    }
                end
            end
        else
            for k, v in pairs(t[1]) do
                p[#p+1] = v[1]
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
