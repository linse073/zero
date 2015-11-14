
local data

local stage = {}

function stage.init(userdata)
    data = userdata
end

function stage.exit()
    data = nil
end

return stage
