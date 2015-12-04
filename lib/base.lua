
local base = {
    MAX_ROLE = 4,

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

    -- card
    MAX_CARD_STAR = 6,

    CARD_SOUL_COUNT = {
        10, 30, 80, 180, 360, 660,
    },

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
    ITEM_TYPE_BLUE_STORE = 13,
    ITEM_TYPE_RED_STORE = 14,
    ITEM_TYPE_YELLOW_STORE = 15,
    ITEM_TYPE_GREEN_STORE = 16,
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
}

return base
