local skynet = require "skynet"
local util = require "util"
local sharedata = require "sharedata"
local new_rand = require "random"

local ipairs = ipairs
local base
local day_second = 24 * 60 * 60
local start_routine_time = tonumber(skynet.getenv("start_routine_time"))
local randi = new_rand.randi

skynet.init(function()
    base = sharedata.query("base")
end)

local func = {}

function func.game_day(t)
    local st = util.day_time(t)
    return (st - start_routine_time) // day_second
end

function func.gen_itemid(prof, level, itemtype, quality)
    return 3000000000 + prof * 1000000 + level * 1000 + itemtype * 10 + quality
end

function func.is_equip(itemtype)
    return itemtype >= base.ITEM_TYPE_HEAD and itemtype <= base.ITEM_TYPE_NECKLACE
end

function func.is_material(itemtype)
    return itemtype >= base.ITEM_TYPE_IRON and itemtype <= base.ITEM_TYPE_GEM
end

function func.is_stone(itemtype)
    return itemtype >= base.ITEM_TYPE_BLUE_STONE and itemtype <= base.ITEM_TYPE_GREEN_CRYSTAL
end

function func.is_chest(itemtype)
    return itemtype >= base.ITEM_TYPE_CHEST and itemtype <= base.ITEM_TYPE_AUTO_CHEST
end

function func.map_pos(des_pos)
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

function func.rand_bonus(d, p)
    local rand = randi(d.total_rate)
    local t = 0
    for k, v in ipairs(d.all_rate) do
        t = t + v.rate
        if rand <= t then
            local bonus = {num=v.num, data=v.data}
            if v.type == base.BONUS_TYPE_EQUIP then
                local prof
                if v.prof then
                    prof = p
                else
                    prof = randi(base.PROF_WARRIOR, base.PROF_WIZARD)
                end
                local level = v.level // 5 * 5
                local itemtype = v.equipType
                if itemtype == 0 then
                    itemtype = randi(base.ITEM_TYPE_HEAD, base.ITEM_TYPE_NECKLACE)
                end
                bonus.item = func.gen_itemid(prof, level, itemtype, v.quality)
            elseif v.type == base.BONUS_TYPE_MATERIAL then
                local itemtype = v.item_type
                if itemtype == 0 then
                    itemtype = randi(base.ITEM_TYPE_IRON, base.ITEM_TYPE_SPAR)
                end
                bonus.item = func.gen_itemid(0, 0, itemtype, v.quality)
            elseif v.type == base.BONUS_TYPE_STONE then
                local itemtype = v.item_type
                if itemtype == 0 then
                    itemtype = randi(base.ITEM_TYPE_BLUE_STONE, base.ITEM_TYPE_GREEN_CRYSTAL)
                end
                bonus.item = func.gen_itemid(0, 0, itemtype, v.quality)
            elseif v.type == base.BONUS_TYPE_PASSIVE_EXP then
                local itemtype = v.item_type
                if itemtype == 0 then
                    itemtype = randi(base.ITEM_TYPE_FIRE_EXP, base.ITEM_TYPE_MAGIC_EXP)
                end
                bonus.item = func.gen_itemid(0, 0, itemtype, v.quality)
            else
                bonus.item = v.item
            end
            return bonus
        end
    end
end

function func.get_item_slot(level)
    local i = 0
    for k, v in ipairs(base.SLOT_LEVEL_LIMIT) do
        if level >= v then
            i = k
        else
            break
        end
    end
    return i
end

return func
