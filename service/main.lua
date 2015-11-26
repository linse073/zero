local skynet = require "skynet"
local snax = require "snax"
local sharedata = require "sharedata"

local pairs = pairs

skynet.start(function()
	print("Server start")
    -- debug service
    skynet.newservice("monitor", 9000)
	skynet.newservice("console")
	skynet.newservice("debug_console", 8000)

    -- share data
    sharedata.new("carddata", require("data.card"))
    sharedata.new("itemdata", require("data.item"))
    sharedata.new("stagedata", require("data.stage"))
    sharedata.new("taskdata", require("data.task"))

    sharedata.new("base", require("base"))
    sharedata.new("error_code", require("error_code"))

    local taskdata = sharedata.query("taskdata")
    local base = sharedata.query("base")
    local day_task = {}
    local achi_task = {}
    for k, v in pairs(taskdata) do
        if v.TaskType == base.TASK_TYPE_DAY then
            local t = day_task[v.levelLimit]
            if t then
                t[#t+1] = v
            else
                day_task[v.levelLimit] = {v}
            end
        elseif v.TaskType == base.TASK_TYPE_ACHIEVEMENT then
            if v.levelLimit == 0 then
                achi_task[#achi_task+1] = v
            end
        end
    end
    sharedata.new("day_task", day_task)
    sharedata.new("achi_task", achi_task)

    local msg = {
        [1000] = "error_code",
        [1001] = "notify_info",
        [1002] = "nope",
        [1003] = "heart_beat",
        [1004] = "heart_beat_response",

        [2000] = "simple_user",
        [2001] = "account_info",
        [2002] = "user_info",
        [2003] = "item_info",
        [2004] = "card_info",
        [2005] = "stage_info",
        [2006] = "task_info",
        [2007] = "friend_info",
        [2007] = "rank_info",
        [2008] = "user_all",

        [2100] = "get_account_info",
        [2101] = "create_user",
        [2102] = "enter_game",
    }
    local name_msg = {}
    for k, v in pairs(msg) do
        name_msg[v] = k
    end
    sharedata.new("msg", msg)
    sharedata.new("name_msg", name_msg)

    -- service
	skynet.uniqueservice("protoloader")
    snax.uniqueservice("dbmaster")
    snax.uniqueservice("server_mgr")
    snax.uniqueservice("routine")
    snax.uniqueservice("role_mgr")
    snax.uniqueservice("agent_mgr")

	local loginserver = skynet.newservice("login")
	local gate = skynet.newservice("gate", loginserver)
	skynet.call(gate, "lua", "open" , {
        address = "127.0.0.1",
		port = 8888,
		maxclient = 64,
		servername = "sample",
	})
	skynet.call(gate, "lua", "open" , {
        address = "127.0.0.1",
		port = 8889,
		maxclient = 64,
		servername = "sample",
	})

    snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6379,
        db = 0,
        name = "accountdb"
    })
    snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6379,
        db = 1,
        name = "userdb"
    })
    snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6379,
        db = 2,
        name = "namedb"
    })
    snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6379,
        db = 3,
        name = "tradedb"
    })
    snax.newservice("dbslave", {
        host = "127.0.0.1",
        port = 6379,
        db = 4,
        name = "rankdb"
    })

    snax.newservice("server", {
        serverid = 1,
        servername = "sample",
    })
    
    skynet.exit()
end)
