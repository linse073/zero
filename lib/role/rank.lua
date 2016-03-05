local skynet = require "skynet"
local share = require "share"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string

local data
local base
local error_code
local rank_field
local rank_mgr

local rank = {}
local proc = {}

skynet.init(function()
    base = share.base
    error_code = share.error_code
    rank_field = share.rank_field
    rank_mgr = skynet.queryservice("rank_mgr")
end)

function rank.init_module()
    return proc
end

function rank.init(userdata)
    data = userdata
end

function rank.exit()
    data = nil
end

---------------------------protocol process----------------------

function proc.query_rank(msg)
    local field = rank_field[msg.rank_type]
    if not filed then
        error{code = error_code.ERROR_QUERY_RANK_TYPE}
    end
    local user = data.user
    skynet.call(rank_mgr, "lua", "query", msg.rank_type, user.id, user[field])
    return "response", ""
end

return rank
