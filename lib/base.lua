
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
    BEGIN_TASK_ID = 900000011,

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
    
    TASK_COMPLETE_CARD = 200,
    TASK_COMPLETE_UPGRADE_CARD = 201,
    TASK_COMPLETE_PROMOTE_CARD = 202,
    TASK_COMPLETE_USE_CARD = 203,
    
    TASK_COMPLETE_USE_ITEM = 300,
    TASK_COMPLETE_COMPOUND_ITEM = 301,
    TASK_COMPLETE_UPGRADE_ITEM = 302,
    TASK_COMPLETE_IMPROVE_ITEM = 303,
    TASK_COMPLETE_DECOMPOSE_ITEM = 304,
    TASK_COMPLETE_INTENSIFY_ITEM = 305,
    TASK_COMPLETE_INLAY_ITEM = 306,
    TASK_COMPLETE_UNINLAY_ITEM = 307,

    TASK_COMPLETE_STAGE = 400,
    TASK_COMPLETE_TALK = 401,

    -- card
    MAX_EQUIP_CARD = 4,
    MAX_CARD_POSITION_TYPE = 2,
    MAX_CARD_STAR_LEVEL = 16,

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

    ITEM_DEFENCE = 1,
    ITEM_ATTACK = 2,

    ITEM_STATUS_NORMAL = 0,
    ITEM_STATUS_SELLING = 1,
    ITEM_STATUS_SELLED = 2,
    ITEM_STATUS_DELETE = 3,

    ITEM_RAND_DEFENCE = 1,
    ITEM_RAND_TENACITY = 2,
    ITEM_RAND_HARD = 3,
    ITEM_RAND_OFFSET = 4,
    
    ITEM_RAND_BREAK = 5,
    ITEM_RAND_CRIT = 6,
    ITEM_RAND_IMPALE = 7,
    ITEM_RAND_HIT = 8,

    MAX_RAND_PROP = 2,
    
    INTENSIFY_ITEM = 3000000210,
    MAX_INTENSIFY = 18,

    -- bonus
    BONUS_TYPE_MONEY = 1,
    BONUS_TYPE_EQUIP = 2,
    BONUS_TYPE_ITEM = 3,
    BONUS_TYPE_MATERIAL = 4,
    BONUS_TYPE_STONE = 5,
}

return base
