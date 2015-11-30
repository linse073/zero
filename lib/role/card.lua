local share = require "share"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string

local carddata
local base
local data

local card = {}
local proc = {}

skynet.init(function()
    carddata = share.carddata
    base = share.base
end)

function card.init(userdata)
    data = userdata
end

function card.exit()
    data = nil
end

function card.enter()
    local pack = {}
    local dc = {}
    data.card = dc
    data.equip_card = {}
    for k, v in pairs(data.user.card) do
        card.add(v)
        pack[#pack+1] = v
    end
    return "card", pack
end

function card.add(v, d)
    if not d then
        d = assert(carddata[v.id], string.format("No card data %d.", v.id))
    end
    local c = {v, d}
    if v.star_exp == 0 then
        v.star_exp = base.CARD_SOUL_COUNT[d.starLv]
    end
    if v.pos ~= 0 then
        if data.equip_card[v.pos] then
            skynet.error(string.format("Already equip card %d in position %d.", v.id, v.pos))
        else
            v.pos = 0
        end
    end
    data.card[k] = c
    return c
end

function card.add_by_id(id)
    local v = {
        id = id,
        exp = 0,
        star_exp = 0,
        pos = 0,
    }
    local c = card.add(v)
    data.user.card[id] = v
    return c
end

function card.get_proc()
    return proc
end

--------------------------protocol process-----------------------

return card
