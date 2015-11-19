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

return share
