
local data

local friend = {}
local proc = {}

function friend.init(userdata)
    data = userdata
end

function friend.exit()
    data = nil
end

function friend.enter()
    local pack = {}
    data.friend = data.user.friend
    for k, v in pairs(data.friend) do
        pack[#pack+1] = v
    end
    return "friend", pack
end

function friend.get_proc()
    return proc
end

---------------------------protocol process----------------------

return friend
