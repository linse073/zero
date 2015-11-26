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

    msg = sharedata.query("msg"),
    name_msg = sharedata.query("name_msg"),

    -- share in current service
    sproto = sprotoloader.load(1)
}

local base = share.base

-- item
function share.is_equip(itemtype)
    return itemtype >= base.ITEM_TYPE_HEAD and itemtype <= base.ITEM_TYPE_NECKLACE
end

local item_category = {
    [base.ITEM_TYPE_HEAD] = base.ITEM_DEFENCE,
    [base.ITEM_TYPE_BODY] = base.ITEM_DEFENCE,
    [base.ITEM_TYPE_WEAPON] = base.ITEM_ATTACK,
    [base.ITEM_TYPE_ACCESSORY] = base.ITEM_ATTACK,
    [base.ITEM_TYPE_FOOT] = base.ITEM_DEFENCE,
    [base.ITEM_TYPE_HAND] = base.ITEM_DEFENCE,
    [base.ITEM_TYPE_RING] = base.ITEM_ATTACK,
    [base.ITEM_TYPE_NECKLACE] = base.ITEM_ATTACK,
}
function share.item_category(itemtype)
    return item_category[itemtype]
end

return share
