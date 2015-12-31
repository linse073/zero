local crypt = require "crypt"

local string = string
local tostring = tostring
local b64decode = crypt.base64decode
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
        local vt = type(v)
        if vt == "string" then
            text = text .. v
        elseif vt == "number" or vt == "boolean" then
            text = text .. tostring(v)
        elseif vt == "table" then
            text = text .. table_to_string(v)
        end
    end
    return text
end

function util.check_sign(t, secret)
    local sign = t.sign
    t.sign = nil
    return b64decode(sign) == hmac_hash(secret, table_to_string(t))
end

return util
