local pairs = pairs
local ipairs = ipairs
local table = table

local type_code = {
    [0] = {
        OK="成功",
    },

    [1000] = {
        INTERNAL_ERROR = "数据错误",
    },

    [1100] = {
        ALREADY_NOTIFY = "重复提示",
        ERROR_ARGS = "参数错误",
        ERROR_SIGN = "签名错误",
    },

    [2000] = {
        MAX_ROLE = "角色数量已达上限",
        ROLE_NAME_EXIST = "角色名字重复",
        ROLE_NOT_EXIST = "角色不存在",
        ROLE_LEVEL_LIMIT = "玩家等级不足",
        ERROR_ROLE_PROFESSION = "职业不符",
        ROLE_IS_ENTERING = "正在登录中",
        ROLE_ALREADY_ENTER = "重复登陆",
        PROFESSION_NOT_EXIST = "职业不存在",
        ROLE_NOT_ENTER = "尚未登陆",
        ROLE_NO_PERMIT = "角色权限不足",
        ROLE_MONEY_LIMIT = "游戏币不足",
        ROLE_RMB_LIMIT = "钻石不足",
        ROLE_OFFLINE = "玩家离线",
        ROLE_VIP_LIMIT = "vip等级不足",
        ROLE_CONTRIBUTE_LIMIT = "贡献不足",
        ROLE_CHARGE_LIMIT = "充值不足",
        IOS_CHARGE_FAIL = "苹果充值失败",
    },

    [2100] = {
        ITEM_NOT_EXIST = "物品不存在",
        ERROR_ITEM_POSITION = "装备位置错误",
        ERROR_ITEM_STATUS = "物品状态错误",
        ITEM_ID_NOT_EXIST = "非法物品",
        CAN_NOT_COMPOUND_ITEM = "物品无法合成",
        ITEM_NUM_LIMIT = "物品数量不足",
        ERROR_ITEM_TYPE = "物品类型错误",
        CAN_NOT_UPGRADE_ITEM = "装备无法升级",
        CAN_NOT_IMPROVE_ITEM = "装备无法进阶",
        ITEM_IN_USE = "物品正在使用中",
        MAX_INTENSIFY = "装备强化等级已达上限",
        ITEM_LEVEL_LIMIT = "物品等级不足",
        ITEM_QUALITY_LIMIT = "物品品质不足",
        ITEM_HAS_STONE = "装备已镶嵌宝石",
        CAN_NOT_DECOMPOSE_ITEM = "装备无法分解",
        MAX_QUALITY = "品质已达上限",
        STONE_IN_POSITION = "已经镶嵌宝石",
        NO_STONE_IN_POSITION = "尚未镶嵌宝石",
        ERROR_ITEM_NUM = "物品数目错误",
    },

    [2200] = {
        TASK_NOT_EXIST = "任务不存在",
        NOT_MASTER_TASK = "不是主线任务",
    },

    [2300] = {
        CARD_ID_NOT_EXIST = "非法魔物",
        CARD_CAN_NOT_CALL = "魔物无法召唤",
        ALREADY_HAS_CARD = "已经拥有该魔物",
        CARD_SOUL_LIMIT = "魔物碎片不足",
        CARD_NOT_EXIST = "魔物不存在",
        MAX_CARD_STAR_LEVEL = "魔物星级已达上限",
        CARD_CAN_NOT_EVOLVE = "魔物无法进化",
        CARD_EVOLVE_ITEM_LIMIT = "魔物进化果实不足",
        ERROR_CARD_POSITION_TYPE = "魔物位置类型错误",
        ERROR_CARD_POSITION = "魔物位置错误",
        CARD_NO_PASSIVE_SKILL = "魔物没有被动技能",
        EQUIP_CARD_LIMIT = "上阵卡牌不足",
    },

    [2400] = {
        STAGE_ID_NOT_EXIST = "关卡不存在",
        PRE_STAGE_NOT_COMPLETE = "前置关卡未完成",
        STAGE_COUNT_LIMIT = "关卡次数已达上限",
        ERROR_STAGE_SEED = "关卡种子错误",
        ERROR_STAGE_STATE = "关卡信息错误",
        ALREADY_GET_STAGE_BONUS = "关卡宝箱已经打开",
        STAGE_STAR_LIMIT = "关卡星数不足",
        ERROR_STAGE_AREA = "错误关卡区域",
        ALREADY_GET_STAGE_AWRAD = "关卡奖励已经领取",
        REVIVE_COUNT_LIMIT = "复活次数已达上限",
    },

    [2500] = {
        ERROR_QUERY_RANK_TYPE = "排行榜查询类型错误",
        NOT_IN_RANK = "不在排行榜中",
        ARENA_COUNT_LIMIT = "排位赛次数已达上限",
        CHALLENGE_TIME_LIMIT = "还未到下次挑战时间",
        MATCH_COUNT_LIMIT = "竞技场次数已达上限",
        ERROR_CHALLENGE_TARGET = "挑战对象不一致",
        ALREADY_WIN_MATCH = "已经战胜过对手",
        CHALLENGE_NOT_CD = "已经可以挑战",
        ERROR_SLAVE_RANK = "排行榜类型错误",
    },

    [2600] = {
        ALREADY_SIGN_IN = "已经签到",
        NO_PATCH_SIGN_IN = "无法补签",
        EXCHANGE_LIMIT = "今日兑换金币次数已达上限",
        ERROR_CHARGE_NUM = "错误的充值数额",
        NO_ONLINE_AWARD = "还没有在线奖励",
        ALREADY_GET_CHARGE_AWARD = "已经领取充值奖励",
        OFFLINE_EXP_COUNT_LIMIT = "钻石充能次数已达上限",
    },

    [2700] = {
        ALREADY_EXPLORE = "已经在探索",
        ERROR_EXPLORE_AREA = "非法探索区域",
        NOT_EXPLORE = "尚未探索",
        ERROR_EXPLORE_STATUS = "探索状态错误",
    },

    [2800] = {
        ERROR_CHAT_TYPE = "聊天类型错误",
    },
    
    [2900] = {
        MAIL_NOT_EXIST = "邮件不存在",
        ERROR_MAIL_STATUS = "邮件状态错误",
    },

    [3000] = {
        ERROR_FRIEND_NAME = "好友名字错误",
        NO_FRIEND_REQUEST = "好友请求不存在",
        ERROR_FRIEND_STATUS = "好友状态错误",
        ALREADY_BE_FRIEND = "已经是好友",
        IN_BLACKLIST = "对方把你加入黑名单",
        ALREADY_REQUEST_FRIEND = "已经请求加为好友",
        ALREADY_IN_BLACKLIST = "已经加入黑名单",
        FRIEND_NOT_EXIST = "好友不存在",
    },

    [3100] = {
        NO_SELL_ITEM = "出售物品不存在",
        BUY_SELF_ITEM = "购买自己的出售物品",
        TRADE_WATCH_COUNT_LIMIT = "关注数量已达上限",
        ALREADY_TRADE_WATCH = "已关注",
        NO_TRADE_WATCH = "尚未关注",
        ITEM_CANNOT_SELL = "此物品不能出售",
        LOWER_ITEM_PRICE = "物品售价过低",
        HIGHER_ITEM_PRICE = "物品售价过高",
        ERROR_MALL_ITEM = "商城物品错误",
        ERROR_RANDOM_MALL = "随机上架物品错误",
        MALL_COUNT_LIMIT = "商城物品已达上限",
        MALL_TIME_LIMIT = "限时物品错误",
        ERROR_COST_TYPE = "错误的货币类型",
        ERROR_GUILD_ITEM = "补给站物品错误",
        GUILD_ITEM_COUNT_LIMIT = "补给站物品不足",
    },

    [3200] = {
        ALREADY_HAS_GUILD = "已经加入冒险团",
        GUILD_NOT_EXIST = "冒险团不存在",
        ALREADY_APPLY_GUILD = "已经申请冒险团",
        GUILD_NAME_EXIST = "冒险团名字已存在",
        NOT_JOIN_GUILD = "还未加入冒险团",
        NOT_GUILD_MEMBER = "非冒险团成员",
        NO_GUILD_PERMIT = "冒险团权限不够",
        GUILD_DISMISS_LIMIT = "冒险团成员只剩一人才可解散",
        TARGET_HAS_GUILD = "对方已经加入冒险团",
        TARGET_NOT_APPLY_GUILD = "对方并未申请冒险团",
        TARGET_NOT_GUILD_MEMBER = "对方不是冒险团成员",
        TARGET_PROMOTE_LIMIT = "对方已经是副团长",
        TARGET_DEMOTE_LIMIT = "对方不是副团长",
        PROMOTE_COUNT_LIMIT = "副团长人数上限",
        GUILD_MEMBER_LIMIT = "冒险团人数上限",
        RANDOM_JOIN_GUILD_LIMIT = "没有可以一键申请的冒险团",
        GUILD_CHIEF_QUIT_LIMIT = "团战不能离开冒险团",
        GUILD_EXPLORE_LIMIT = "探索值不足",
        GUILD_SKILL_UPLIMIT = "冒险团科技等级已达上限",
        GUILD_PRESKILL_LIMIT = "冒险团前置科技尚未完成",
    },
}

local code = {}
local code_string = {}

for k, v in pairs(type_code) do
    local t = {}
    for k1, v1 in pairs(v) do
        t[#t+1] = k1
    end
    table.sort(t)
    for k1, v1 in ipairs(t) do
        local i = k + k1
        code[v1] = i
        code_string[i] = v[v1]
    end
end

return {code=code, code_string=code_string}
