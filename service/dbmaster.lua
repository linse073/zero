local skynet = require "skynet"

local slave_list = {}

function init()
    
end

function exit()
    
end

function response.register_slave(conf, handle, typename)
    slave_list[conf.name] = {handle, typename}
end

function response.get_slave(name)
    local slave = slave_list[name]
    if slave then
        return slave[1], slave[2]
    end
end

function response.get_slave_by_aid(aid)
    
end
