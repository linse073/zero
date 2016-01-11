
local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string

local data

local friend = {}
local proc = {}

function friend.init_module()
    return proc
end

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

function friend.add(v)
    data.friend[v.id] = v
end

---------------------------protocol process----------------------

return friend
