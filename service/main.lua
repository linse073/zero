local skynet = require "skynet"
local snax = require "snax"
local sharedata = require "sharedata"

local pairs = pairs

skynet.start(function()
	print("Server start")

    -- share data
    sharedata.new("carddata", "@data.card")
    sharedata.new("itemdata", "@data.item")
    sharedata.new("stagedata", "@data.stage")
    sharedata.new("taskdata", "@data.task")

    sharedata.new("base", "@base")
    sharedata.new("error_code", "@error_code")

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

        [1100] = "simple_user",
        [1101] = "account_info",
        [1102] = "user_info",
        [1103] = "item_info",
        [1104] = "card_info",
        [1105] = "stage_info",
        [1106] = "task_info",
        [1107] = "friend_info",
        [1107] = "rank_info",
        [1108] = "user_all",

        [1200] = "get_account_info",
        [1201] = "create_user",
        [1202] = "enter_game",
    }
    local name_msg = {}
    for k, v in pairs(msg) do
        name_msg[v] = k
    end
    sharedata.new("msg", msg)
    sharedata.new("name_msg", name_msg)

    -- service
	skynet.newservice("console")
	skynet.newservice("debug_console", 8000)
	skynet.uniqueservice("proto.protoloader")

	local loginserver = skynet.newservice("login")
	local gate = skynet.newservice("gate", loginserver)
	skynet.call(gate, "lua", "open" , {
		port = 8888,
		maxclient = 64,
		servername = "sample",
	})

    snax.uniqueservice("dbmaster")
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

    snax.uniqueservice("server_mgr")
    snax.newservice("server", {
        serverid = 1,
    })

    snax.uniqueservice("routine")
    snax.uniqueservice("role_mgr")
    snax.uniqueservice("agent_mgr")
    
    skynet.exit()
end)
