local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local sharedata = require "sharedata"
local proto = require "proto"

skynet.start(function()
    -- share data
    sharedata.new("carddata", require("data.card"))
    sharedata.new("itemdata", require("data.item"))
    sharedata.new("stagedata", require("data.stage"))
    sharedata.new("taskdata", require("data.task"))

    sharedata.new("base", require("base"))
    sharedata.new("error_code", require("error_code"))

    local taskdata = sharedata.query("taskdata")
    local base = sharedata.query("base")
    local day_task = {}
    local achi_task = {}
    for k, v in pairs(taskdata) do
        if v.TaskType == base.TASK_TYPE_DAY then
            local t = day_task[v.levelLimit]
            if t then
                t[#t+1] = v
            else
                day_task[v.levelLimit] = {v}
            end
        elseif v.TaskType == base.TASK_TYPE_ACHIEVEMENT then
            if v.levelLimit == 0 then
                achi_task[#achi_task+1] = v
            end
        end
    end
    sharedata.new("day_task", day_task)
    sharedata.new("achi_task", achi_task)

    sharedata.new("item_category", {
        [base.ITEM_TYPE_HEAD] = base.ITEM_DEFENCE,
        [base.ITEM_TYPE_BODY] = base.ITEM_DEFENCE,
        [base.ITEM_TYPE_WEAPON] = base.ITEM_ATTACK,
        [base.ITEM_TYPE_ACCESSORY] = base.ITEM_ATTACK,
        [base.ITEM_TYPE_FOOT] = base.ITEM_DEFENCE,
        [base.ITEM_TYPE_HAND] = base.ITEM_DEFENCE,
        [base.ITEM_TYPE_RING] = base.ITEM_ATTACK,
        [base.ITEM_TYPE_NECKLACE] = base.ITEM_ATTACK,
    })

    sharedata.new("msg", proto.msg)
    sharedata.new("name_msg", proto.name_msg)

    -- protocol
    local file = skynet.getenv("root").."proto/proto.sp"
    sprotoloader.register(file, 1)
	-- don't call skynet.exit(), because sproto.core may unload and the global slot become invalid
end)
