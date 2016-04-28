
local error = error
local pcall = pcall

local function wrapper(f, ...)
    return pcall(f, ...)
end

local function ret(ok, ...)
    if ok then
        return ...
    else
        return error(...)
    end
end

local function queue(cs, f, ...)
    return ret(cs(wrapper, f, ...))
end

return queue
