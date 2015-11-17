local sharedata = require "sharedata"

local share = {
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
}

return share
