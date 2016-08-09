
local msg = {
    [1000] = "error_code",
    [1001] = "notify_info",
    [1002] = "logout",
    [1003] = "heart_beat",
    [1004] = "heart_beat_response",
    [1005] = "response",
    [1006] = "update_day",

    [2000] = "simple_user",
    [2001] = "account_info",
    [2002] = "user_info",
    [2003] = "item_info",
    [2004] = "card_info",
    [2005] = "stage_info",
    [2006] = "task_info",
    [2007] = "friend_info",
    [2008] = "rank_info",
    [2009] = "user_all",
    [2010] = "info_all",
    [2011] = "update_user",
    [2012] = "other_info",
    [2013] = "other_all",
    [2014] = "update_other",
    [2015] = "move",
    [2016] = "get_role_info",
    [2017] = "role_info",

    [2100] = "get_account_info",
    [2101] = "create_user",
    [2102] = "enter_game",

    [2200] = "use_item",
    [2201] = "compound_item",
    [2202] = "upgrade_item",
    [2203] = "improve_item",
    [2204] = "decompose_item",
    [2205] = "intensify_item",
    [2206] = "inlay_item",
    [2207] = "uninlay_item",

    [2300] = "submit_task",

    [2400] = "call_card",
    [2401] = "upgrade_card",
    [2402] = "promote_card",
    [2403] = "use_card",
    [2404] = "upgrade_passive",

    [2500] = "begin_stage",
    [2501] = "end_stage",
    [2502] = "stage_seed",
    [2503] = "open_chest",
    [2504] = "get_stage_award",

    [2600] = "add_item",
    [2601] = "add_exp",
    [2602] = "add_level",
    [2603] = "add_money",
    [2604] = "add_rmb",
    [2605] = "set_task",
    [2606] = "add_mail",
    [2607] = "broadcast_mail",
    [2608] = "test_charge",
    [2609] = "reset_online_award",

    [2700] = "query_rank",
    [2701] = "rank_list",
    [2702] = "begin_challenge",
    [2703] = "end_challenge",
    [2704] = "reflesh_arena",

    [2800] = "sign_in",
    [2801] = "exchange",
    [2802] = "online_award",

    [2900] = "explore",
    [2901] = "quit_explore",
    [2902] = "confirm_explore",
    [2903] = "explore_fight",

    [3000] = "chat_info",

    [3100] = "read_mail",
    [3101] = "del_mail",

    [3200] = "request_friend",
    [3201] = "confirm_friend",
    [3202] = "blacklist",
    [3203] = "del_friend",
    [3204] = "query_friend",
    [3205] = "old_friend",
    [3206] = "query_friend_info",

    [3300] = "query_sell",
    [3301] = "query_sell_info",
    [3302] = "sell_item",
    [3303] = "back_item",
    [3304] = "buy_item",
    [3305] = "add_watch",
    [3306] = "del_watch",
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
