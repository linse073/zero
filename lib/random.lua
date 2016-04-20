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
    return rand.rand(r, min, max)
end

return random
