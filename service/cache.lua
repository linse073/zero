local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local sharedata = require "sharedata"
local proto = require "proto"

local string = string
local tonumber = tonumber

skynet.start(function()
    -- share data
    local carddata = require("data.card")
    sharedata.new("carddata", carddata)
    sharedata.new("itemdata", require("data.item"))
    sharedata.new("stagedata", require("data.stage"))
    local taskdata = require("data.task")
    sharedata.new("taskdata", taskdata)
    sharedata.new("expdata", require("data.exp"))
    sharedata.new("intensifydata", require("data.intensify"))

    local base = require("base")
    sharedata.new("base", base)
    sharedata.new("error_code", require("error_code"))

    local bonusdata = require("data.bonus")
    for k, v in pairs(bonusdata) do
        local rt = {}
        local total_rate = 0
        if v.MoneyRate > 0 then
            rt[#rt+1] = {
                type = base.BONUS_TYPE_MONEY,
                num = v.Money,
                rate = v.MoneyRate,
            }
            total_rate = total_rate + v.MoneyRate
        end
        local equip_quality = v.EquipQuality
        for k1, v1 in ipairs(v.EquipRate) do
            if v1 > 0 then
                rt[#rt+1] = {
                    type = base.BONUS_TYPE_EQUIP,
                    level = v.EquipLv,
                    prof = v.EquipJob,
                    quality = equip_quality[k1],
                    rate = v1,
                }
                total_rate = total_rate + v1
            end
        end
        for item, num, rate in string.gmatch(v.dropItem, "(%d+);(%d+);(%d+)") do
            local r = tonumber(rate)
            rt[#rt+1] = {
                type = base.BONUS_TYPE_ITEM,
                item = tonumber(item),
                num = tonumber(num),
                rate = r,
            }
            total_rate = total_rate + r
        end
        if v.MatRate > 0 then
            rt[#rt+1] = {
                type = base.BONUS_TYPE_MATERIAL,
                item_type = v.MatType,
                quality = v.MatQua,
                num = v.MatNum,
                rate = v.MatRate,
            }
            total_rate = total_rate + v.MatRate
        end
        if v.StoneRate > 0 then
            rt[#rt+1] = {
                type = base.BONUS_TYPE_STONE,
                item_type = v.StoneType,
                quality = v.StoneQua,
                num = v.StoneNum,
                rate = v.StoneRate,
            }
            total_rate = total_rate + v.StoneRate
        end
        if total_rate < base.RAND_FACTOR then
            local r = base.RAND_FACTOR - total_rate
            rt[#rt+1] = {
                type = base.BONUS_TYPE_MONEY,
                num = v.MinMoney,
                rate = r,
            }
            total_rate = base.RAND_FACTOR
        end
        v.all_rate = rt
        v.total_rate = total_rate
    end
    sharedata.new("bunusdata", bonusdata)

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

    local original_card = {}
    for k, v in pairs(carddata) do
        local original = original_card[k] or k
        local d = v
        repeat
            original_card[d.id] = original
            d = carddata[d.evolveId]
        until not d
    end
    sharedata.new("original_card", original_card)

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
