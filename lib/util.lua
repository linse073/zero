
local string = string

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

return util
