
local data

local item = {}

function item.init(userdata)
    data = userdata
end

function item.exit()
    data = nil
end

return item
