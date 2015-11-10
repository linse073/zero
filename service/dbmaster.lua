local slave_list = {}

function init()
    
end

function exit()
    
end

function response.register_slave(conf, handle, typename)
    assert(not slave_list[conf.name], string.format("Already register database slave %s.", conf.name))
    local slave = {
        handle = handle, 
        typename = typename
    }
    slave_list[conf.name] = slave
end

function response.get_slave(name)
    local slave = slave_list[name]
    assert(slave, string.format("Has not database slave %s.", name))
    return slave.handle, slave.typename
end
