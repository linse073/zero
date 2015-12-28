local skynet = require "skynet"
local sharedata = require "sharedata"
local sprotoloader = require "sprotoloader"
local queue = require "skynet.queue"

local share = {}
local base

-- item
function share.is_equip(itemtype)
    return itemtype >= base.ITEM_TYPE_HEAD and itemtype <= base.ITEM_TYPE_NECKLACE
end

function share.is_material(itemtype)
    return itemtype >= base.ITEM_TYPE_IRON and itemtype <= base.ITEM_TYPE_GEM
end

function share.is_stone(itemtype)
    return itemtype >= base.ITEM_TYPE_BLUE_STONE and itemtype <= base.ITEM_TYPE_GREEN_CRYSTAL
end

skynet.init(function()
    -- share with all service
    share.cardata = sharedata.query("carddata")
    share.itemdata = sharedata.query("itemdata")
    share.stagedata = sharedata.query("stagedata")
    share.taskdata = sharedata.query("taskdata")

    share.base = sharedata.query("base")
    share.error_code = sharedata.query("error_code")

    share.day_task = sharedata.query("day_task")
    share.achi_task = sharedata.query("achi_task")

    share.item_category = sharedata.query("item_category")

    share.msg = sharedata.query("msg")
    share.name_msg = sharedata.query("name_msg")

    -- share in current service
    share.sproto = sprotoloader.load(1)
    share.cs = queue()

    -- local variable
    base = share.base
end)

return share
