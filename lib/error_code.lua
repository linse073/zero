
local error_code = {
    OK = 0,

    INTERNAL_ERROR = 1000,

    ALREADY_NOTIFY = 1100,

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
    ERROR_STAGE_SIGN = 2403,
    ERROR_STAGE_SEED = 2404,
    ERROR_STAGE_STATE = 2405,
    ALREADY_GET_STAGE_BONUS = 2406,
    STAGE_STAR_LIMIT = 2407,
    ERROR_STAGE_AREA = 2408,

    ERROR_QUERY_RANK_TYPE = 2500,
    NOT_IN_RANK = 2501,

    ALREADY_SIGN_IN = 2600,
    NO_PATCH_SIGN_IN = 2601,

    ALREADY_EXPLORE = 2700,
    ERROR_EXPLORE_AREA = 2701,
    NOT_EXPLORE = 2702,
    ERROR_EXPLORE_STATUS = 2703,
}

return error_code
