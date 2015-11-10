local skynet = require "skynet"
local sprotoloader = require "sprotoloader"

skynet.start(function()
    local file = skynet.getenv("root").."lib/proto/proto.sp"
    sprotoloader.register(file, 1)
	-- don't call skynet.exit(), because sproto.core may unload and the global slot become invalid
end)
