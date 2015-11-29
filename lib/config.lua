
local config = {}

local login = {
	host = "127.0.0.1",
	port = 8001,
    multilogin = true, -- allow same user login different server
	name = "login_master",
}

local sample = {
    serverid = 1,
    servername = "sample",
    gate = {
        {
            address = "127.0.0.1",
            port = 8888,
            maxclient = 64,
        },
        {
            address = "127.0.0.1",
            port = 8889,
            maxclient = 64,
        },
    },
    db = {
        {
            host = "127.0.0.1",
            port = 6379,
            db = 0,
            name = "accountdb",
        },
        {
            host = "127.0.0.1",
            port = 6379,
            db = 1,
            name = "userdb",
        },
        {
            host = "127.0.0.1",
            port = 6379,
            db = 2,
            name = "namedb",
        },
    },
}

local db = {
    {
        host = "127.0.0.1",
        port = 6379,
        db = 3,
        name = "tradedb",
    },
    {
        host = "127.0.0.1",
        port = 6379,
        db = 4,
        name = "rankdb",
    },
}

config.login = login
config.game = {sample}
config.db = db

return config
