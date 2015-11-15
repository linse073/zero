
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
    data.friend = data.user.friend
end

function friend.get_proc()
    return proc
end

---------------------------protocol process----------------------

return friend
