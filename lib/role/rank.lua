
local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string

local data

local rank = {}
local proc = {}

function rank.init_module()
    return proc
end

function rank.init(userdata)
    data = userdata
end

function rank.exit()
    data = nil
end

---------------------------protocol process----------------------

return rank
