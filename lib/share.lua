local sharedata = require "sharedata"
local sprotoloader = require "sprotoloader"

local share = {
    -- share with all service
    cardata = sharedata.query("carddata"),
    itemdata = sharedata.query("itemdata"),
    stagedata = sharedata.query("stagedata"),
    taskdata = sharedata.query("taskdata"),

    base = sharedata.query("base"),
    error_code = sharedata.query("error_code"),

    day_task = sharedata.query("day_task"),
    achi_task = sharedata.query("achi_task"),

    item_category = sharedata.query("item_category"),

    msg = sharedata.query("msg"),
    name_msg = sharedata.query("name_msg"),

    -- share in current service
    sproto = sprotoloader.load(1)
}

local base = share.base
local item_category = share.item_category

-- item
function share.is_equip(itemtype)
    return itemtype >= base.ITEM_TYPE_HEAD and itemtype <= base.ITEM_TYPE_NECKLACE
end

function share.get_item_category(itemtype)
    return item_category[itemtype]
end

return share
