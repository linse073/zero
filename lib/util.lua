local crypt = require "crypt"

local pairs = pairs
local ipairs = ipairs
local type = type
local string = string
local tostring = tostring
local b64decode = crypt.base64decode
local b64encode = crypt.base64encode
local hmac_hash = crypt.hmac_hash
local traceback = debug.traceback

local util = {}

-- base function
function util.merge(t1, t2)
    for k, v in ipairs(t2) do
        t1[#t1+1] = v
    end
end

function util.merge_table(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
end

function util.gen_key(serverid, key)
    return string.format("%d@%s", serverid, key)
end

function util.gen_id(uid, servername)
    return string.format("%s@%s", uid, servername)
end

local function table_to_string(t)
    local text = ""
    for k, v in pairs(t) do
        text = text .. to_string(v)
    end
    return text
end

local function to_string(v)
    local vt = type(v)
    if vt == "string" then
        return v
    elseif vt == "number" or vt == "boolean" then
        return to_string(v)
    elseif vt == "table" then
        return table_to_string(v)
    end
end

function util.check_sign(t, secret)
    local sign = t.sign
    t.sign = nil
    return b64decode(sign) == hmac_hash(secret, to_string(t))
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

    local tb = string.split(traceback("", 2), "\n")
    print("dump from: " .. string.trim(tb[3]))

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, desciption)
            else
                result[#result +1 ] = string.format("%s%s = {", indent, _v(desciption))
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
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end

return util
