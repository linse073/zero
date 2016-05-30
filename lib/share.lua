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

    share.base = sharedata.query("base")
    share.error_code = sharedata.query("error_code")

    share.day_task = sharedata.query("day_task")
    share.achi_task = sharedata.query("achi_task")
    share.original_card = sharedata.query("original_card")
    share.type_reward = sharedata.query("type_reward")

    share.max_exp = sharedata.query("max_exp")

    share.item_category = sharedata.query("item_category")
    share.complete_task = sharedata.query("complete_task")

    share.msg = sharedata.query("msg")
    share.name_msg = sharedata.query("name_msg")

    -- share in current service
    share.sproto = sprotoloader.load(1)
    share.cs = queue() -- avoid dead lock, there is only one queue in a agent
end)

return share
