local crypt = require "crypt"

local pairs = pairs
local ipairs = ipairs
local type = type
local string = string
local tostring = tostring
local b64decode = crypt.base64decode
local b64encode = crypt.base64encode
local hmac_hash = crypt.hmac_hash

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

return util
