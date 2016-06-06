local crypt = require "crypt"

local pairs = pairs
local ipairs = ipairs
local type = type
local string = string
local table = table
local tostring = tostring
local b64decode = crypt.base64decode
local b64encode = crypt.base64encode
local hmac_hash = crypt.hmac_hash
local traceback = debug.traceback
local os = os
local date = os.date
local time = os.time

local util = {}

-- base function
function util.merge(t1, t2)
    for k, v in ipairs(t2) do
        t1[#t1 + 1] = v
    end
end

function util.merge_table(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
end

function util.clone(t)
    local nt = {}
    for k, v in pairs(t) do
        nt[k] = v
    end
    return nt
end

function util.gen_key(serverid, key)
    return string.format("%d@%s", serverid, key)
end

function util.gen_id(uid, servername)
    return string.format("%s@%s", uid, servername)
end

local to_string
local function table_to_string(t)
    local ks = {}
    for k, _ in pairs(t) do
        ks[#ks + 1] = k
    end
    table.sort(ks)
    local text = ""
    for _, v in ipairs(ks) do
        text = text .. to_string(t[v])
    end
    return text
end

to_string = function(v)
    local vt = type(v)
    if vt == "string" then
        return v
    elseif vt == "number" or vt == "boolean" then
        return tostring(v)
    elseif vt == "table" then
        return table_to_string(v)
    end
end

function util.check_sign(t, secret)
    local sign = t.sign
    t.sign = nil
    return sign == util.sign(t, secret)
end

function util.sign(t, secret)
    return b64encode(hmac_hash(secret, to_string(t)))
end

function util.update_user()
    return {
        user = {},
        item = {},
        stage = {},
        task = {},
        card = {},
        friend = {},
    }
end

function util.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

function util.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function util.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function util.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == '') then return false end
    local pos, arr = 0, {}
    -- for each divider found
    for st, sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function util.dump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local tb = util.split(traceback("", 2), "\n")
    print("dump from: " .. util.trim(tb[3]))

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result + 1] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result + 1] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result + 1] = string.format("%s%s = *MAX NESTING*", indent, desciption)
            else
                result[#result + 1] = string.format("%s%s = {", indent, _v(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result + 1] = string.format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end

function util.day_time(t)
    local st = date("*t", t)
    if st.hour >= 4 then
        st.day = st.day + 1
    end
    st.hour = 4
    st.min = 0
    st.sec = 0
    return time(st)
end

return util
