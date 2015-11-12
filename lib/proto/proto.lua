local msg = {
    [1000] = "error_code",

    [1100] = "simple_user",
    [1101] = "account_info",
    [1102] = "user_info",
    [1103] = "item_info",
    [1104] = "card_info",
    [1105] = "stage_info",
    [1106] = "task_info",
    [1107] = "friend_info",
    [1107] = "rank_info",
    [1108] = "user_all",

    [1200] = "get_account_info",
    [1201] = "create_user",
    [1202] = "enter_game",
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
