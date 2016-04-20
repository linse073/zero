local rand = require "rand"

local r = rand.new(19650218)

local random = {}

function random.init(seed)
    rand.init(r, seed)
end

function random.rand(min, max)
    if not max then
        min, max = 1, min
    end
    local num = rand.rand(r, min, max)
    print("rand num", num)
    return num
    -- return rand.rand(r, max)
end

return random
