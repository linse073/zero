
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
    [2018] = "guild_member",
    [2019] = "guild_log",
    [2020] = "guild_apply",
    [2021] = "guild_info",
    [2022] = "guild_rank_info",
    [2023] = "guild_all",
    [2024] = "guild_skill",
    [2025] = "apple_charge",

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
    [2505] = "fight_fail",
    [2506] = "revive",

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
    [2610] = "test_update_day",
    [2611] = "add_guild_explore",
    [2612] = "add_contribute",

    [2700] = "query_rank",
    [2701] = "rank_list",
    [2702] = "begin_challenge",
    [2703] = "end_challenge",
    [2704] = "refresh_arena",
    [2705] = "slave_rank",
    [2706] = "slave_rank_list",
    [2707] = "task_rank",
    [2708] = "task_rank_info",

    [2800] = "sign_in",
    [2801] = "exchange",
    [2802] = "online_award",
    [2803] = "add_offline_exp",
    [2804] = "get_offline_exp",
    [2805] = "first_charge_award",

    [2900] = "explore",
    [2901] = "quit_explore",
    [2902] = "explore_fight",

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
    [3307] = "mall_item",
    [3308] = "guild_item",

    [3400] = "list_guild",
    [3401] = "list_guild_info",
    [3402] = "query_guild",
    [3403] = "query_guild_info",
    [3404] = "query_apply",
    [3405] = "query_apply_info",
    [3406] = "apply_guild",
    [3407] = "found_guild",
    [3408] = "dismiss_guild",
    [3409] = "guild_notice",
    [3410] = "guild_apply_level",
    [3411] = "guild_apply_vip",
    [3412] = "accept_apply",
    [3413] = "accept_all_apply",
    [3414] = "refuse_apply",
    [3415] = "refuse_all_apply",
    [3416] = "guild_expel",
    [3417] = "guild_promote",
    [3418] = "guild_demote",
    [3419] = "guild_demise",
    [3420] = "quit_guild",
    [3421] = "get_apply",
    [3422] = "apply_info",
    [3423] = "guild_icon",
    [3424] = "upgrade_guild_skill",
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
