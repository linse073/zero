
local data

local friend = {}

function friend.init(userdata)
    data = userdata
end

function friend.exit()
    data = nil
end

return friend
