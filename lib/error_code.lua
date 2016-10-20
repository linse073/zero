
local error_code = {
    OK = 0,

    INTERNAL_ERROR = 1000,

    ALREADY_NOTIFY = 1100,
    ERROR_ARGS = 1101,
    ERROR_SIGN = 1102,

    MAX_ROLE = 2000,
    ROLE_NAME_EXIST = 2001,
    ROLE_NOT_EXIST = 2002,
    ROLE_LEVEL_LIMIT = 2003,
    ERROR_ROLE_PROFESSION = 2004,
    ROLE_IS_ENTERING = 2005,
    ROLE_ALREADY_ENTER = 2006,
    PROFESSION_NOT_EXIST = 2007,
    ROLE_NOT_ENTER = 2008,
    ROLE_NO_PERMIT = 2009,
    ROLE_MONEY_LIMIT = 2010,
    ROLE_RMB_LIMIT = 2011,
    ROLE_OFFLINE = 2012,
    ROLE_VIP_LIMIT = 2013,

    ITEM_NOT_EXIST = 2100,
    ERROR_ITEM_POSITION = 2101,
    ERROR_ITEM_STATUS = 2102,
    ITEM_ID_NOT_EXIST = 2103,
    CAN_NOT_COMPOUND_ITEM = 2104,
    ITEM_NUM_LIMIT = 2105,
    ERROR_ITEM_TYPE = 2106,
    CAN_NOT_UPGRADE_ITEM = 2107,
    CAN_NOT_IMPROVE_ITEM = 2108,
    ITEM_IN_USE = 2109,
    MAX_INTENSIFY = 2110,
    ITEM_LEVEL_LIMIT = 2111,
    ITEM_QUALITY_LIMIT = 2112,
    ITEM_HAS_STONE = 2113,
    CAN_NOT_DECOMPOSE_ITEM = 2114,
    MAX_QUALITY = 2115,
    STONE_IN_POSITION = 2116,
    NO_STONE_IN_POSITION = 2117,
    ERROR_ITEM_NUM = 2118,

    TASK_NOT_EXIST = 2200,
    NOT_MASTER_TASK = 2201,

    CARD_ID_NOT_EXIST = 2300,
    CARD_CAN_NOT_CALL = 2301,
    ALREADY_HAS_CARD = 2302,
    CARD_SOUL_LIMIT = 2303,
    CARD_NOT_EXIST = 2304,
    MAX_CARD_STAR_LEVEL = 2305,
    CARD_CAN_NOT_EVOLVE = 2306,
    CARD_EVOLVE_ITEM_LIMIT = 2307,
    ERROR_CARD_POSITION_TYPE = 2308,
    ERROR_CARD_POSITION = 2309,
    CARD_NO_PASSIVE_SKILL = 2310,
    EQUIP_CARD_LIMIT = 2311,

    STAGE_ID_NOT_EXIST = 2400,
    PRE_STAGE_NOT_COMPLETE = 2401,
    STAGE_COUNT_LIMIT = 2402,
    ERROR_STAGE_SEED = 2403,
    ERROR_STAGE_STATE = 2404,
    ALREADY_GET_STAGE_BONUS = 2405,
    STAGE_STAR_LIMIT = 2406,
    ERROR_STAGE_AREA = 2407,
    ALREADY_GET_STAGE_AWRAD = 2408,
    REVIVE_COUNT_LIMIT = 2409,

    ERROR_QUERY_RANK_TYPE = 2500,
    NOT_IN_RANK = 2501,
    ARENA_COUNT_LIMIT = 2502,
    CHALLENGE_TIME_LIMIT = 2503,
    MATCH_COUNT_LIMIT = 2504,
    ERROR_CHALLENGE_TARGET = 2505,
    ALREADY_WIN_MATCH = 2506,
    CHALLENGE_NOT_CD = 2507,
    ERROR_SLAVE_RANK = 2508,

    ALREADY_SIGN_IN = 2600,
    NO_PATCH_SIGN_IN = 2601,
    EXCHANGE_LIMIT = 2602,
    ERROR_CHARGE_NUM = 2603,
    NO_ONLINE_AWARD = 2604,

    ALREADY_EXPLORE = 2700,
    ERROR_EXPLORE_AREA = 2701,
    NOT_EXPLORE = 2702,
    ERROR_EXPLORE_STATUS = 2703,

    ERROR_CHAT_TYPE = 2800,

    MAIL_NOT_EXIST = 2900,
    ERROR_MAIL_STATUS = 2901,

    ERROR_FRIEND_NAME = 3000,
    NO_FRIEND_REQUEST = 3001,
    ERROR_FRIEND_STATUS = 3002,
    ALREADY_BE_FRIEND = 3003,
    IN_BLACKLIST = 3004,
    ALREADY_REQUEST_FRIEND = 3005,
    ALREADY_IN_BLACKLIST = 3006,
    FRIEND_NOT_EXIST = 3007,
    
    NO_SELL_ITEM = 3100,
    BUY_SELF_ITEM = 3101,
    TRADE_WATCH_COUNT_LIMIT = 3102,
    ALREADY_TRADE_WATCH = 3103,
    NO_TRADE_WATCH = 3104,
    ITEM_CANNOT_SELL = 3105,
    LOWER_ITEM_PRICE = 3106,
    HIGHER_ITEM_PRICE = 3107,
    ERROR_MALL_ITEM = 3108,
    ERROR_RANDOM_MALL = 3109,
    MALL_COUNT_LIMIT = 3110,
    MALL_TIME_LIMIT = 3111,
    ERROR_COST_TYPE = 3112,

    ALREADY_HAS_GUILD = 3200,
    GUILD_NOT_EXIST = 3201,
    ALREADY_APPLY_GUILD = 3202,
    GUILD_NAME_EXIST = 3203,
    NOT_JOIN_GUILD = 3204,
    NOT_GUILD_MEMBER = 3205,
    NO_GUILD_PERMIT = 3206,
    GUILD_DISMISS_LIMIT = 3207,
    TARGET_HAS_GUILD = 3208,
    TARGET_NOT_APPLY_GUILD = 3209,
    TARGET_NOT_GUILD_MEMBER = 3210,
    TARGET_PROMOTE_LIMIT = 3211,
    TARGET_DEMOTE_LIMIT = 3212,
    PROMOTE_COUNT_LIMIT = 3213,
    GUILD_MEMBER_LIMIT = 3214,
    RANDOM_JOIN_GUILD_LIMIT = 3215,
}

return error_code
