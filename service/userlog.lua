local skynet = require "skynet"
require "skynet.manager"
local timer = require "timer"

local date = os.date
local floor = math.floor

local p
local f

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = function(_, address, msg)
		p(string.format("[%s][%s]: %s", skynet.address(address), date("%X", floor(skynet.time())), msg))
	end
}

local function change_log()
    if f then
        f:close()
    end
    local name = date("%m_%d_%Y.log", floor(skynet.time()))
    f = io.open(name, "a")
end

local function print_file(msg)
    
end

local CMD = {}

function CMD.day_routine(key)
    timer.call_day_routine(key)
end

skynet.start(function()
	skynet.register ".logger"
    if skynet.getenv("daemon") then
        change_log()
        timer.add_day_routine("change_log", change_log)
        p = print_file
    else
        p = print
    end

	skynet.dispatch("lua", function(session, source, command, ...)
		assert(CMD[command])(...)
	end)
end)
