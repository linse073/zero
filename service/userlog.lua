local skynet = require "skynet"
require "skynet.manager"

local date = os.date
local floor = math.floor

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = function(_, address, msg)
		print(string.format("[%s][%s]: %s", skynet.address(address), date("%m/%d/%Y %X", floor(skynet.time())), msg))
	end
}

skynet.start(function()
	skynet.register ".logger"
end)
