
local msg = {
    [1000] = "error_code",
    [1001] = "notify_info",
    [1002] = "nope",
    [1003] = "heart_beat",
    [1004] = "heart_beat_response",

    [2000] = "simple_user",
    [2001] = "account_info",
    [2002] = "user_info",
    [2003] = "item_info",
    [2004] = "card_info",
    [2005] = "stage_info",
    [2006] = "task_info",
    [2007] = "friend_info",
    [2007] = "rank_info",
    [2008] = "user_all",

    [2100] = "get_account_info",
    [2101] = "create_user",
    [2102] = "enter_game",
}
local name_msg = {}

for k, v in pairs(msg) do
    name_msg[v] = k
end

local proto = {
    msg = msg,
    name_msg = name_msg,
}

function proto.get_id(name)
    return name_msg[name]
end

function proto.get_name(id)
    return msg[id]
end

return proto
