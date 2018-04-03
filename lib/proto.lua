local pairs = pairs
local ipairs = ipairs

local type_msg = {
    [1000] = {
        "error_code",
        "notify_info",
        "logout",
        "heart_beat",
        "heart_beat_response",
        "response",
        "update_day",
    },

    [2000] = {
        "simple_user",
        "account_info",
        "user_info",
        "item_info",
        "card_info",
        "stage_info",
        "task_info",
        "friend_info",
        "rank_info",
        "user_all",
        "info_all",
        "update_user",
        "other_info",
        "other_all",
        "update_other",
        "move",
        "get_role_info",
        "role_info",
        "guild_member",
        "guild_log",
        "guild_apply",
        "guild_info",
        "guild_rank_info",
        "guild_all",
        "guild_skill",
        "apple_charge",
    },

    [2100] = {
        "get_account_info",
        "create_user",
        "enter_game",
    },

    [2200] = {
        "use_item",
        "compound_item",
        "upgrade_item",
        "improve_item",
        "decompose_item",
        "intensify_item",
        "inlay_item",
        "uninlay_item",
    },

    [2300] = {
        "submit_task",
    },

    [2400] = {
        "call_card",
        "upgrade_card",
        "promote_card",
        "use_card",
        "upgrade_passive",
    },

    [2500] = {
        "begin_stage",
        "end_stage",
        "stage_seed",
        "open_chest",
        "get_stage_award",
        "fight_fail",
        "revive",
    },

    [2600] = {
        "add_item",
        "add_exp",
        "add_level",
        "add_money",
        "add_rmb",
        "set_task",
        "add_mail",
        "broadcast_mail",
        "test_charge",
        "reset_online_award",
        "test_update_day",
        "add_guild_explore",
        "add_contribute",
    },

    [2700] = {
        "query_rank",
        "rank_list",
        "begin_challenge",
        "end_challenge",
        "refresh_arena",
        "slave_rank",
        "slave_rank_list",
        "task_rank",
        "task_rank_info",
    },

    [2800] = {
        "sign_in",
        "exchange",
        "online_award",
        "add_offline_exp",
        "get_offline_exp",
        "first_charge_award",
    },

    [2900] = {
        "explore",
        "quit_explore",
        "explore_fight",
    },

    [3000] = {
        "chat_info",
    },

    [3100] = {
        "read_mail",
        "del_mail",
    },

    [3200] = {
        "request_friend",
        "confirm_friend",
        "blacklist",
        "del_friend",
        "query_friend",
        "old_friend",
        "query_friend_info",
    },

    [3300] = {
        "query_sell",
        "query_sell_info",
        "sell_item",
        "back_item",
        "buy_item",
        "add_watch",
        "del_watch",
        "mall_item",
        "guild_item",
    },

    [3400] = {
        "list_guild",
        "list_guild_info",
        "query_guild",
        "query_guild_info",
        "query_apply",
        "query_apply_info",
        "apply_guild",
        "found_guild",
        "dismiss_guild",
        "guild_notice",
        "guild_apply_level",
        "guild_apply_vip",
        "accept_apply",
        "accept_all_apply",
        "refuse_apply",
        "refuse_all_apply",
        "guild_expel",
        "guild_promote",
        "guild_demote",
        "guild_demise",
        "quit_guild",
        "get_apply",
        "apply_info",
        "guild_icon",
        "upgrade_guild_skill",
    },
}

local msg = {}
local name_msg = {}

for k, v in pairs(type_msg) do
    for k1, v1 in ipairs(v) do
        local i = k + k1
        msg[i] = v1
        name_msg[v1] = i
    end
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
