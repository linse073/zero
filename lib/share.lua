local skynet = require "skynet"
local sharedata = require "sharedata"
local sprotoloader = require "sprotoloader"
local queue = require "skynet.queue"

local share = {}

skynet.init(function()
    -- share with all service
    share.carddata = sharedata.query("carddata")
    share.itemdata = sharedata.query("itemdata")
    share.stagedata = sharedata.query("stagedata")
    share.taskdata = sharedata.query("taskdata")
    share.expdata = sharedata.query("expdata")
    share.intensifydata = sharedata.query("intensifydata")
    share.bonusdata = sharedata.query("bonusdata")
    share.passivedata = sharedata.query("passivedata")
    share.npcdata = sharedata.query("npcdata")
    share.propertydata = sharedata.query("propertydata")
    share.rewarddata = sharedata.query("rewarddata")
    share.searchdata = sharedata.query("searchdata")
    share.textdata = sharedata.query("textdata")
    share.vipdata = sharedata.query("vipdata")
    share.malldata = sharedata.query("malldata")
    share.taskrankdata = sharedata.query("taskrankdata")
    share.guildtechdata = sharedata.query("guildtechdata")

    share.base = sharedata.query("base")
    share.error_code = sharedata.query("error_code")

    share.day_task = sharedata.query("day_task")
    share.achi_task = sharedata.query("achi_task")
    share.week_task = sharedata.query("week_task")
    share.original_card = sharedata.query("original_card")
    share.class_card = sharedata.query("class_card")
    share.normal_card = sharedata.query("normal_card")
    share.card_soul = sharedata.query("card_soul")
    share.card_quality = sharedata.query("card_quality")
    share.type_reward = sharedata.query("type_reward")
    share.area_search = sharedata.query("area_search")
    share.area_stage = sharedata.query("area_stage")
    share.stage_reward = sharedata.query("stage_reward")
    share.vip_level = sharedata.query("vip_level")
    share.mall_sale = sharedata.query("mall_sale")
    share.mall_limit = sharedata.query("mall_limit")
    share.task_rank_type = sharedata.query("task_rank_type")
    share.guild_tech_effect = sharedata.query("guild_tech_effect")

    share.max_exp = sharedata.query("max_exp")

    share.item_category = sharedata.query("item_category")
    share.complete_task = sharedata.query("complete_task")
    share.stage_task = sharedata.query("stage_task")
    share.stage_task_complete = sharedata.query("stage_task_complete")
    share.random_sale = sharedata.query("random_sale")
    share.guild_store = sharedata.query("guild_store")

    share.msg = sharedata.query("msg")
    share.name_msg = sharedata.query("name_msg")

    -- share in current service
    share.sproto = sprotoloader.load(1)
    share.cs = queue() -- avoid dead lock, there is only one queue in a agent
end)

return share
