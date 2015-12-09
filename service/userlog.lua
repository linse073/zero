local skynet = require "skynet"
require "skynet.manager"

local date = os.date
local floor = math.floor

local p
local f

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = function(_, address, msg)
		p(string.format("[%s][%s]: %s", skynet.address(address), date("%m/%d/%Y %X", floor(skynet.time())), msg))
	end
}

local function change_log()
    if f then
        f:close()
    end
    local name = skynet.getenv("root").."log/"..date("%m_%d_%Y.log", floor(skynet.time()))
    f = assert(io.open(name, "a"), string.format("Can't open log file %s.", name))
    skynet.timeout(8640000, change_log) -- one day
end

local function print_file(msg)
    f:write(msg .. "\n")
    f:flush()
end

skynet.start(function()
	skynet.register ".logger"
    if skynet.getenv("daemon") then
        change_log()
        p = print_file
    else
        p = print
    end
end)
