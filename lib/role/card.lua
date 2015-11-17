local share = require "share"

local carddata = share.carddata
local data

local card = {}
local proc = {}

function card.init(userdata)
    data = userdata
end

function card.exit()
    data = nil
end

function card.enter()
    local pack = {}
    data.card = {}
    for k, v in pairs(data.user.card) do
        data.card[k] = {v, assert(carddata[v.id], string.format("No card data %d.", v.id))}
        pack[#pack+1] = v
    end
    return "card", pack
end

function card.get_proc()
    return proc
end

--------------------------protocol process-----------------------

return card
