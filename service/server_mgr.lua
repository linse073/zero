local server_list = {}

function init()
    
end

function exit()
    
end

function response.register_server(conf, handle, typename)
    assert(not server_list[conf.serverid], string.format("Already register server %d.", conf.serverid))
    local server = {
        handle = handle,
        typename = typename
    }
    server_list[conf.serverid] = server
end

function response.get_server(serverid)
    local server = server_list[serverid]
    assert(server, string.format("No server %d.", serverid))
    return server.handle, server.typename
end
