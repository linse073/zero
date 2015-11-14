
local data

local task = {}

function task.init(userdata)
    data = userdata
end

function task.exit()
    data = nil
end

return task
