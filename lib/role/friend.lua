
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
    data.friend = data.user.friend
end

function friend.pack_all()
    local pack = {}
    for k, v in pairs(data.user.friend) do
        pack[#pack+1] = v
    end
    return "friend", pack
end

function friend.add(v)
    data.friend[v.id] = v
end

---------------------------protocol process----------------------

return friend
