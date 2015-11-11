local msg = {
    [1000] = "error_code",

    [1100] = "get_account_info",
    [1101] = "account_info",
}
local name_msg = {}

for k, v in pairs(msg) do
    name_msg[v] = k
end

local proto = {}

function proto.get_id(name)
    return name_msg[name]
end

function proto.get_name(id)
    return proto[id]
end

return proto
