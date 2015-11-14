
local data

local card = {}

function card.init(userdata)
    data = userdata
end

function card.exit()
    data = nil
end

return card
