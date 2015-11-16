
local role_list = {}

function init()
    
end

function exit()
    
end

function response.role_enter(roleid, agent)
    assert(not role_list[roleid], string.format("Role already enter %d.", roleid))
    role_list[roleid] = agent
end

function response.role_exit(roleid)
    role_list[roleid] = nil
end

function response.get_role(roleid)
    return assert(role_list[roleid])
end
