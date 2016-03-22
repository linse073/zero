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

function share.map_pos(des_pos)
    local map_rect = base.MAP_RECT
    if des_pos.x < map_rect.x then
        des_pos.x = map_rect.x
    elseif des_pos.x > map_rect.ex then
        des_pos.x = map_rect.ex
    end
    if des_pos.y < map_rect.y then
        des_pos.y = map_rect.y
    elseif des_pos.y > map_rect.ey then
        des_pos.y = map_rect.ey
    end
end

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

    share.base = sharedata.query("base")
    share.error_code = sharedata.query("error_code")

    share.day_task = sharedata.query("day_task")
    share.achi_task = sharedata.query("achi_task")
    share.original_card = sharedata.query("original_card")

    share.max_exp = sharedata.query("max_exp")

    share.item_category = sharedata.query("item_category")

    share.msg = sharedata.query("msg")
    share.name_msg = sharedata.query("name_msg")

    -- share in current service
    share.sproto = sprotoloader.load(1)
    share.cs = queue() -- avoid dead lock, there is only one queue in a agent

    -- local variable
    base = share.base
end)

return share
