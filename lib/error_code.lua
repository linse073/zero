
local error_code = {
    OK = 0,

    INTERNAL_ERROR = 1000,

    ALREADY_NOTIFY = 1100,

    MAX_ROLE = 2000,
    ROLE_NAME_EXIST = 2001,
    ROLE_NOT_EXIST = 2002,
    ROLE_LEVEL_LIMIT = 2003,
    ERROR_ROLE_PROFESSION = 2004,

    ITEM_NOT_EXIST = 2100,
    ERROR_ITEM_POSITION = 2101,
    ERROR_ITEM_STATUS = 2102,
}

return error_code
