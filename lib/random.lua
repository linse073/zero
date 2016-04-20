local rand = require "rand"

local r = rand.new(19650218)

local random = {}

function random.init(seed)
    rand.init(r, seed)
end

function random.rand(max)
    local num = rand.rand(r, max)
    print("rand num", num)
    return num
    -- return rand.rand(r, max)
end

return random
