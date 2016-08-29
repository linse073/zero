
local base = {
    MAX_ROLE = 4,
    MAX_LEVEL = 100,
    RAND_FACTOR = 10000,
    FLOAT_FACTOR = 1000,

    PROF_WARRIOR = 1,
    PROF_ASSASSIN = 2,
    PROF_GUNNER = 3,
    PROF_WIZARD = 4,

    -- task
    BEGIN_TASK_ID = 900000001,

    TASK_TYPE_MASTER = 1,
    TASK_TYPE_DAY = 2,
    TASK_TYPE_ACHIEVEMENT = 3,

    TASK_STATUS_NOT_ACCEPT = 0,
    TASK_STATUS_ACCEPT = 1,
    TASK_STATUS_DONE = 2,
    TASK_STATUS_FINISH = 3,
    
    MAX_DAY_TASK = 10,
    
    TASK_COMPLETE_LEVEL = 100,
    TASK_COMPLETE_MONEY = 101,
    TASK_COMPLETE_RMB = 102,
    TASK_COMPLETE_FIGHT_POINT = 103,
    TASK_COMPLETE_USE_MONEY = 104,
    TASK_COMPLETE_USE_RMB = 105,
    
    TASK_COMPLETE_CARD = 200,
    TASK_COMPLETE_UPGRADE_CARD = 201,
    TASK_COMPLETE_PROMOTE_CARD = 202,
    TASK_COMPLETE_USE_CARD = 203,
    TASK_COMPLETE_UPGRADE_PASSIVE = 204,
    
    TASK_COMPLETE_USE_ITEM = 300,
    TASK_COMPLETE_COMPOUND_ITEM = 301,
    TASK_COMPLETE_UPGRADE_ITEM = 302,
    TASK_COMPLETE_IMPROVE_ITEM = 303,
    TASK_COMPLETE_DECOMPOSE_ITEM = 304,
    TASK_COMPLETE_INTENSIFY_ITEM = 305,
    TASK_COMPLETE_INLAY_ITEM = 306,
    TASK_COMPLETE_UNINLAY_ITEM = 307,
    TASK_COMPLETE_INTENSIFY_ITEM_FAIL = 308,

    TASK_COMPLETE_STAGE = 400,
    TASK_COMPLETE_TALK = 401,
    TASK_COMPLETE_SIGN_IN = 402,
    TASK_COMPLETE_ROUTINE = 403,
    TASK_COMPLETE_ELITE_STAGE_GUIDE = 404,
    TASK_COMPLETE_STAGE_GUIDE = 405,
    TASK_COMPLETE_EXPLORE_GUIDE = 406,
    TASK_COMPLETE_NEW_FUNCTION = 407,
    TASK_COMPLETE_EXPLORE = 408,

    TASK_COMPLETE_CHAPTER = 500,
    TASK_COMPLETE_MONSTER = 501,
    TASK_COMPLETE_STAGE_COUNT = 502,
    TASK_COMPLETE_EXPLORE_ENCOUNTER = 503,
    TASK_COMPLETE_OPEN_CHEST = 504,
    TASK_COMPLETE_PICK_GOLD = 505,
    TASK_COMPLETE_STAGE_STAR = 506,

    -- card
    MAX_EQUIP_CARD = 4,
    MAX_CARD_POSITION_TYPE = 2,
    MAX_CARD_STAR_LEVEL = 15,

    CARD_TYPE_NORMAL = 1,
    CARD_TYPE_CLASS = 2,
    CARD_TYPE_EVOLVE_1 = 3,
    CARD_TYPE_EVOLVE_2 = 4,

    -- item
    ITEM_TYPE_HEAD = 1,
    ITEM_TYPE_BODY = 2,
    ITEM_TYPE_WEAPON = 3,
    ITEM_TYPE_ACCESSORY = 4,
    ITEM_TYPE_FOOT = 5,
    ITEM_TYPE_HAND = 6,
    ITEM_TYPE_RING = 7,
    ITEM_TYPE_NECKLACE = 8,
    ITEM_TYPE_IRON = 9,
    ITEM_TYPE_FUR = 10,
    ITEM_TYPE_WOOL = 11,
    ITEM_TYPE_SPAR = 12,
    ITEM_TYPE_BLUE_STONE = 13,
    ITEM_TYPE_RED_STONE = 14,
    ITEM_TYPE_YELLOW_STONE = 15,
    ITEM_TYPE_GREEN_STONE = 16,
    ITEM_TYPE_BLUE_CRYSTAL = 17,
    ITEM_TYPE_RED_CRYSTAL = 18,
    ITEM_TYPE_YELLOW_CRYSTAL = 19,
    ITEM_TYPE_GREEN_CRYSTAL = 20,
    ITEM_TYPE_GEM = 21,
    ITEM_TYPE_CARD = 22,
    ITEM_TYPE_CARD_CHIP = 23,
    ITEM_TYPE_CHEST = 24,
    ITEM_TYPE_CARD_EXP = 25,
    ITEM_TYPE_MAP = 26,
    ITEM_TYPE_STAGE = 27,
    ITEM_TYPE_SIGN_IN = 28,
    ITEM_TYPE_CHEST = 29,
    ITEM_TYPE_AUTO_CHEST = 30,
    ITEM_TYPE_FIRE_EXP = 31,
    ITEM_TYPE_WATER_EXP = 32,
    ITEM_TYPE_PLANT_EXP = 33,
    ITEM_TYPE_METAL_EXP = 34,
    ITEM_TYPE_ROCK_EXP = 35,
    ITEM_TYPE_POISON_EXP = 36,
    ITEM_TYPE_ELECTRIC_EXP = 37,
    ITEM_TYPE_STRENGTH_EXP = 38,
    ITEM_TYPE_ICE_EXP = 39,
    ITEM_TYPE_MAGIC_EXP = 40,

    ITEM_TYPE_CARD_EXP_BEGIN = 30,

    ITEM_DEFENCE = 1,
    ITEM_ATTACK = 2,

    ITEM_STATUS_NORMAL = 0,
    ITEM_STATUS_SELL = 1,
    ITEM_STATUS_DELETE = 2,

    INTENSIFY_ITEM = 3000000210,
    MAX_INTENSIFY = 18,
    MAX_QUALITY = 6,
    MAX_RAND_PROP = 2,
    MAX_EQUIP = 8,

    -- prop
    PROP_DEFENCE = 1,
    PROP_TENACITY = 2,
    PROP_BLOCK = 3,
    PROP_DODGE = 4,
    
    PROP_SUNDER = 5,
    PROP_CRIT = 6,
    PROP_IMPALE = 7,
    PROP_HIT = 8,

    PROP_HP = 9,
    PROP_ATTACK = 10,
    PROP_MOVE_SPEED = 11,

    -- stage
    STAGE_TYPE_NONE = 0,
    STAGE_TYPE_NORMAL = 1,
    STAGE_TYPE_HARD = 2,
    STAGE_TYPE_TRAP = 3,
    STAGE_TYPE_ARENA = 4,
    STAGE_TYPE_RUNMAP_X = 5,
    STAGE_TYPE_RUNMAP_Y = 6,

    -- bonus
    BONUS_TYPE_EQUIP = 1,
    BONUS_TYPE_ITEM = 2,
    BONUS_TYPE_MATERIAL = 3,
    BONUS_TYPE_STONE = 4,
    BONUS_TYPE_PASSIVE_EXP = 5,

    STAGE_BONUS_COST = {
        "money",
        "rmb",
    },
    MAX_EXTRA_STAGE_BONUS = 2,

    COST_TYPE_MONEY = 1,
    COST_TYPE_RMB = 2,

    -- map
    MAP_RECT = {
        x = 580,
        y = 155,
        ex = 3490,
        ey = 380,
    },
    INIT_RECT = {
        x = 1900,
        y = 155,
        ex = 2600,
        ey = 380,
    },
    MOVE_SPEED = 350,

    -- rank
    RANK_ARENA = 1,
    RANK_FIGHT_POINT = 2,

    RANK_SLAVE_LEVEL = 1,
    RANK_SLAVE_FIGHT = 2,
    RANK_SLAVE_ARENA = 3,
    RANK_SLAVE_EXPLORE = 4,
    RANK_SLAVE_STAGE = 5,

    RANK_STAGE = 1300004001,
    NEWBIE_STAGE = 1300001000,

    PROP_NAME = {
        "defence",
        "tenacity",
        "block",
        "dodge",

        "sunder",
        "crit",
        "impale",
        "hit",

        "hp",
        "attack",
        "moveSpeed",
    },
    
    PROP_FACTOR = {
        hp = 0.0125,
        attack = 0.5,
        moveSpeed = 0,
    },

    PROF_NPC_BASE = 1200000000,
    NEWBIE_CARD = 1600310061,
    MAX_SIGN_IN = 28,

    REWARD_ACTION_ONLINE = 1,
    REWARD_ACTION_SIGN_IN = 2,
    REWARD_ACTION_TOTAL_SIGN_IN = 3,
    REWARD_ACTION_FIRST_CHARGE = 4,
    REWARD_ACTION_CHARGE = 5,
    REWARD_ACTION_VIP = 6,
    REWARD_ACTION_MONTH_CARD_1 = 7,
    REWARD_ACTION_MONTH_CARD_2 = 8,
    REWARD_ACTION_TOTAL_CHARGE = 9,
    REWARD_ACTION_ARENA = 10,
    REWARD_ACTION_NORMAL_STAGE = 11,
    REWARD_ACTION_HERO_STAGE = 12,

    REWARD_TYPE_ITEM = 1,
    REWARD_TYPE_RMB = 2,

    MAX_CHAPTER_STAGE = 5,

    SLOT_LEVEL_LIMIT = {35, 40, 45, 50, 60, 70, 80, 90, 100},

    CHAT_TYPE_WORLD = 1,
    CHAT_TYPE_PRIVATE = 2,

    CHAT_TEXT_FACE = 1,
    CHAT_TEXT_ITEM = 2,

    MAIL_STATUS_UNREAD = 1,
    MAIL_STATUS_READ = 2,
    MAIL_STATUS_DELETE = 3,

    MAIL_TYPE_TEXT = 1,
    MAIL_TYPE_CHEST = 2,
    MAIL_TYPE_EXPLORE = 3,
    MAIL_TYPE_ARENA = 4,
    MAIL_TYPE_TRADE = 5,
    MAIL_TYPE_CHARGE = 6,

    FRIEND_STATUS_OLD = 1,
    FRIEND_STATUS_NEW = 2,
    FRIEND_STATUS_BLACKLIST = 3,
    FRIEND_STATUS_REQUEST = 4,
    FRIEND_STATUS_BEREQUEST = 5,
    FRIEND_STATUS_DELETE = 6,

    MONEY_ITEM = 3000004271,
    RMB_ITEM = 3000012271,
    EXP_ITEM = 3000024271,

    MAX_TRADE_WATCH = 10,
    TRADE_PAGE_ITEM = 6,

    ONLINE_AWARD_TIME = 4 * 60 * 60,
    MATCH_REFRESH_TIME = 2 * 60 * 60,
    MAX_ARENA_COUNT = 10,
    MAX_MATCH_COUNT = 10,
    ARENA_CHALLENGE_TIME = 5 * 60,

    MALL_TYPE_PACK = 1,
    MALL_TYPE_DAY = 2,
    MALL_TYPE_TIME = 3,

    MALL_SALE_NORMAL = 1,
    MALL_SALE_RANDOM_1 = 2,
    MALL_SALE_RANDOM_2 = 3,

    MALL_LIMIT_DAY = 1,
    MALL_LIMIT_WEEK = 2,
    MALL_LIMIT_TIME = 3,

    OFFLINE_EXP_TIME = 12 * 60 * 60,
    MAX_OFFLINE_EXP = 120,

    MAX_REVIVE_COUNT = 10,
}

return base
