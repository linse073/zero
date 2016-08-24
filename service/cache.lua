local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local sharedata = require "sharedata"
local proto = require "proto"

local string = string
local pairs = pairs
local ipairs = ipairs
local assert = assert
local tonumber = tonumber
local os = os
local time = os.time
local language = skynet.getenv("language")

skynet.start(function()
    -- share data
    local carddata = require("data.card")
    local itemdata = require("data.item")
    local stagedata = require("data.stage")
    local taskdata = require("data.task")
    local expdata = require("data.exp")
    local intensifydata = require("data.intensify")
    local bonusdata = require("data.bonus")
    local passivedata = require("data.passive")
    local npcdata = require("data.npc")
    local propertydata = require("data.property")
    local rewarddata = require("data.reward")
    local searchdata = require("data.search")
    local textdata = require("data.text")
    local vipdata = require("data.vip")
    local malldata = require("data.mall")
    local base = require("base")

    local function get_string(id)
        if id == 0 then
            return ""
        else
            local t = assert(textdata[id], string.format("No text data %d.", id))
            return t[language]
        end
    end

    for k, v in pairs(carddata) do
        v.name = get_string(v.name)
        v.skillDes = get_string(v.skillDes)
        v.cardDes = get_string(v.cardDes)
    end

    for k, v in pairs(itemdata) do
        v.name = get_string(v.name)
        v.Description = get_string(v.Description)
    end

    for k, v in pairs(passivedata) do
        v.name = get_string(v.name)
        v.des = get_string(v.des)
    end

    for k, v in pairs(stagedata) do
        v.name = get_string(v.name)
    end

    for k, v in pairs(taskdata) do
        v.taskTitle = get_string(v.taskTitle)
        v.TaskName = get_string(v.TaskName)
        v.TaskTalk = get_string(v.TaskTalk)
    end

    local function is_equip(itemtype)
        return itemtype >= base.ITEM_TYPE_HEAD and itemtype <= base.ITEM_TYPE_NECKLACE
    end
    local function is_chest(itemtype)
        return itemtype >= base.ITEM_TYPE_CHEST and itemtype <= base.ITEM_TYPE_AUTO_CHEST
    end
    for k, v in pairs(itemdata) do
        if v.overlay == 0 then
            v.overlay = 1
        end
        if v.compos > 0 then
            assert(itemdata[v.compos], string.format("No item data %d.", v.compos))
        end
        if is_equip(v.itemType) then
            local needLv = v.needLv
            if v.needLv == 0 then
                needLv = 1
            end
            v.needLvExp = assert(expdata[needLv], string.format("No exp data %d.", needLv))
            if v.quality < base.MAX_QUALITY then
                local improveMat = v.compos + 1
                assert(itemdata[improveMat], string.format("No item data %d.", improveMat))
                local improveItem = k + 1
                assert(itemdata[improveItem], string.format("No item data %d.", improveItem))
            end
            if v.needLv < base.MAX_LEVEL then
                local upgradeItem = k + 5000
                assert(itemdata[upgradeItem], string.format("No item data %d.", upgradeItem))
            end
        elseif is_chest(v.itemType) then
            assert(v.chestID~="", string.format("Illegal chest %d.", v.id))
            local chest = {}
            for bonus in string.gmatch(v.chestID, "(%d+)") do
                local bonusid = tonumber(bonus)
                chest[#chest+1] = assert(bonusdata[bonusid], string.format("No bonus data %d.", bonusid))
            end
            v.chest = chest
        end
        if v.playerSale ~= 0 then
            assert(v.officialPrice~=0, string.format("Error item price %d.", v.id))
            assert(v.min~=0, string.format("Error item min price %d.", v.id))
            v.minPrice = v.min * v.officialPrice // base.RAND_FACTOR
            assert(v.max~=0, string.format("Error item max price %d.", v.id))
            v.maxPrice = v.max * v.officialPrice // base.RAND_FACTOR
        end
    end

    local area_stage = {}
    for k, v in pairs(stagedata) do
        v.bonus = assert(bonusdata[v.bonusID], string.format("No bonus data %d.", v.bonusID))
        v.firstBonus = assert(bonusdata[v.firstBonusID], string.format("No bonus data %d.", v.firstBonusID))
        v.dropBonus = assert(bonusdata[v.dropBonusID], string.format("No bonus data %d.", v.dropBonusID))
        local area = k % 10000 // 10
        local s = area_stage[area]
        if s then
            s[#s+1] = v
        else
            s = {v}
            area_stage[area] = s
        end
    end

    for k, v in pairs(bonusdata) do
        local rt = {}
        local total_rate = 0
        if v.MoneyRate > 0 then
            rt[#rt+1] = {
                type = base.BONUS_TYPE_ITEM,
                item = base.MONEY_ITEM,
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
                    equipType = v.EquipType,
                    quality = equip_quality[k1],
                    rate = v1,
                    num = 1,
                }
                total_rate = total_rate + v1
            end
        end
        for item, num, rate in string.gmatch(v.dropItem, "(%d+);(%d+);(%d+)") do
            local r = tonumber(rate)
            local i = tonumber(item)
            rt[#rt+1] = {
                type = base.BONUS_TYPE_ITEM,
                item = i,
                num = tonumber(num),
                rate = r,
                data = assert(itemdata[i], string.format("No item data %d.", i)),
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
        if v.PassiveExpRate > 0 then
            rt[#rt+1] = {
                type = base.BONUS_TYPE_PASSIVE_EXP,
                item_type = v.PassiveExpType,
                quality = v.PassiveExpQua,
                num = v.PassiveExpNum,
                rate = v.PassiveExpRate,
            }
            total_rate = total_rate + v.PassiveExpRate
        end
        if v.diamondRate > 0 then
            rt[#rt+1] = {
                type = base.BONUS_TYPE_ITEM,
                item = base.RMB_ITEM,
                num = v.diamond,
                rate = v.diamondRate,
            }
            total_rate = total_rate + v.diamondRate
        end
        v.all_rate = rt
        v.total_rate = total_rate
    end

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
            achi_task[#achi_task+1] = v
        end

        local profItem = {}
        for k1, v1 in ipairs(v.profItemId) do
            if v1 > 0 then
                profItem[k1] = assert(itemdata[v1], string.format("No item data %d.", v1))
            end
        end
        v.profItem = profItem
        local awardItem = {}
        for item, num in string.gmatch(v.Item, "(%d+);(%d+)") do
            local itemid = tonumber(item)
            awardItem[#awardItem+1] = {
                item = itemid,
                data = assert(itemdata[itemid], string.format("No item data %d.", itemid)),
                num = tonumber(num),
            }
        end
        v.awardItem = awardItem
        v.task_level = 0
    end

    local original_card = {}
    for k, v in pairs(carddata) do
        local original = original_card[k] or k
        local d = v
        repeat
            original_card[d.id] = original
            d = carddata[d.evolveId]
        until not d

        v.starLvExp = assert(expdata[v.starLv], string.format("No exp data %d.", v.starLv))
        if v.evolveId > 0 then
            v.evolveItemData = assert(itemdata[v.evolveItem], string.format("No item data %d.", v.evolveItem))
        end
        local passive = {}
        for k1, v1 in ipairs(v.PassiveId) do
            if v1 > 0 then
                passive[#passive+1] = assert(passivedata[v1], string.format("No passive data %d.", v1))
            end
        end
        v.passive = passive
    end

    local type_reward = {}
    local stage_reward = {}
    for k, v in pairs(rewarddata) do
        local reward = type_reward[v.type]
        if not reward then
            reward = {}
            type_reward[v.type] = reward
        end
        if v.type == base.REWARD_ACTION_ONLINE then
            reward[#reward+1] = v
        else
            reward[v.data] = v
        end
        if v.type == base.REWARD_ACTION_NORMAL_STAGE then
            stage_reward[100+v.data] = v
        elseif v.type == base.REWARD_ACTION_HERO_STAGE then
            stage_reward[200+v.data] = v
        end
        if v.rewardType == base.REWARD_TYPE_ITEM then
            v.item = assert(itemdata[v.reward], string.format("No item data %d.", v.reward))
        end
    end

    for k, v in pairs(expdata) do
        v.composTotalRatio = v.compos1 + v.compos2 + v.compos5
        v.composRatio = {
            {v.compos1, 1},
            {v.compos1+v.compos2, 2},
            {v.compos1+v.compos2+v.compos5, 5},
        }
    end

    local area_search = {}
    for k, v in pairs(searchdata) do
        v.area = v.stageType * 100 + v.stageId
        v.searchSecond = v.searchTime * 60
        v.bonus = assert(bonusdata[v.bonusId], string.format("No bonus data %d.", v.bonusId))
        area_search[v.area] = v
    end

    local l = 0
    local id = base.BEGIN_TASK_ID
    repeat
        l = l + 1
        local d = assert(taskdata[id], string.format("No task data %d.", id))
        d.task_level = l
        id = d.nextID
    until id == 0

    local vip_level = {}
    for k, v in pairs(vipdata) do
        local giftItem = {}
        local mailItem = {}
        for v1 in string.gmatch(v.GiftList, "(%d+)") do
            local itemid = tonumber(v1)
            giftItem[#giftItem+1] = assert(itemdata[itemid], string.format("No item data %d.", itemid))
            mailItem[#mailItem+1] = {itemid=itemid, num=1}
        end
        v.giftItem = giftItem
        v.mailItem = mailItem
        vip_level[v.vipLv] = v
    end

    local mall_sale = {}
    local mall_limit = {}
    for k, v in pairs(malldata) do
        if v.preVip ~= "" then
            local minVip, maxVip = string.match(v.preVip, "(%d+)~(%d+)")
            v.minVip, v.maxVip = tonumber(minVip), tonumber(maxVip)
        end
        local ms = mall_sale[v.saleType]
        if not ms then
            ms = {}
            mall_sale[v.saleType] = ms
        end
        ms[#ms+1] = v
        if v.limitType ~= 0 then
            local ml = mall_limit[v.limitType]
            if not ml then
                ml = {}
                mall_limit[v.limitType] = ml
            end
            ml[#ml+1] = v
        end
    end

    sharedata.new("carddata", carddata)
    sharedata.new("itemdata", itemdata)
    sharedata.new("stagedata", stagedata)
    sharedata.new("taskdata", taskdata)
    sharedata.new("expdata", expdata)
    sharedata.new("intensifydata", intensifydata)
    sharedata.new("bonusdata", bonusdata)
    sharedata.new("passivedata", passivedata)
    sharedata.new("npcdata", npcdata)
    sharedata.new("propertydata", propertydata)
    sharedata.new("rewarddata", rewarddata)
    sharedata.new("searchdata", searchdata)
    sharedata.new("textdata", textdata)
    sharedata.new("vipdata", vipdata)

    sharedata.new("base", base)
    sharedata.new("error_code", require("error_code"))

    sharedata.new("day_task", day_task)
    sharedata.new("achi_task", achi_task)
    sharedata.new("original_card", original_card)
    sharedata.new("type_reward", type_reward)
    sharedata.new("area_search", area_search)
    sharedata.new("area_stage", area_stage)
    sharedata.new("stage_reward", stage_reward)
    sharedata.new("vip_level", vip_level)
    sharedata.new("mall_sale", mall_sale)
    sharedata.new("mall_limit", mall_limit)

    local level = base.MAX_LEVEL - 1
    local ed = assert(expdata[level], string.format("No exp data %d.", level))
    sharedata.new("max_exp", ed)

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

    sharedata.new("complete_task", {
        [base.TASK_COMPLETE_TALK] = true,
        [base.TASK_COMPLETE_ROUTINE] = true,
        [base.TASK_COMPLETE_EXPLORE_GUIDE] = true,
        [base.TASK_COMPLETE_NEW_FUNCTION] = true,
    })

    sharedata.new("stage_task", {
        [base.TASK_COMPLETE_STAGE] = true,
        [base.TASK_COMPLETE_ELITE_STAGE_GUIDE] = true,
        [base.TASK_COMPLETE_STAGE_GUIDE] = true,
    })

    sharedata.new("stage_task_complete", {
        [base.STAGE_TYPE_NORMAL] = 1,
        [base.STAGE_TYPE_HARD] = 2,
        [base.STAGE_TYPE_TRAP] = 3,
        [base.STAGE_TYPE_RUNMAP_X] = 3,
        [base.STAGE_TYPE_RUNMAP_Y] = 3,
    })

    sharedata.new("explore_status", {
        NORMAL = 1,
        ENCOUNTER = 2,
        IDLE = 3,
        DONE = 4,
        FINISH = 5,
    })

    sharedata.new("explore_reason", {
        NORMAL = 1,
        FAIL = 2,
        ESCAPE = 3,
        QUIT = 4,
    })

    sharedata.new("random_sale", {
        base.MALL_SALE_RANDOM_1,
        base.MALL_SALE_RANDOM_2,
    })

    sharedata.new("msg", proto.msg)
    sharedata.new("name_msg", proto.name_msg)

    -- protocol
    local file = skynet.getenv("root") .. "proto/proto.sp"
    sprotoloader.register(file, 1)
	-- don't call skynet.exit(), because sproto.core may unload and the global slot become invalid
end)
