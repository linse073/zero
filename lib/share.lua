local skynet = require "skynet"
local sharedata = require "sharedata"
local sprotoloader = require "sprotoloader"

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

-- base function
function share.merge(t1, t2)
    for k, v in ipairs(t2) do
        t1[#t1+1] = v
    end
end

function share.merge_talbe(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
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

    -- local variable
    base = share.base
end)

return share
