local proto = {
    [1000] = "AccountInfo"
}
local name_proto = {}

function init()
    for k, v in pairs(proto) do
        name_proto[v] = k
    end
end

function exit()
    
end

function response.get_id(name)
    return name_proto[name]
end

function response.get_name(id)
    return proto[id]
end
