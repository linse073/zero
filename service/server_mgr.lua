
local assert = assert
local string = string

local server_list = {}

function init()
    
end

function exit()
    
end

function response.register_server(conf, handle, typename)
    assert(not server_list[conf.servername], string.format("Already register server %s.", conf.servername))
    local server = {
        handle = handle,
        typename = typename,
    }
    server_list[conf.servername] = server
end

function response.get_server(servername)
    local server = assert(server_list[servername], string.format("No server %s.", servername))
    return server.handle, server.typename
end
