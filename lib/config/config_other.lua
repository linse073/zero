
local config = {}

local base = 9000
local db_base = 10

local login = {
	port = base + 1,
    multilogin = true, -- allow same user login different server
	name = "login_master",
}

local sample = {
    serverid = 1,
    servername = "sample",
    gate = {
        {
            port = base + 888,
            maxclient = 64,
        },
        {
            port = base + 889,
            maxclient = 64,
        },
    },
    db = {
        {
            host = "127.0.0.1",
            port = 6379,
            db = db_base,
            name = "accountdb",
        },
        {
            host = "127.0.0.1",
            port = 6379,
            db = db_base + 1,
            name = "userdb",
        },
        {
            host = "127.0.0.1",
            port = 6379,
            db = db_base + 2,
            name = "namedb",
        },
    },
}

local db = {
    {
        host = "127.0.0.1",
        port = 6379,
        db = db_base + 3,
        name = "tradedb",
    },
    {
        host = "127.0.0.1",
        port = 6379,
        db = db_base + 4,
        name = "rankdb",
    },
}

config.login = login
config.game = {sample}
config.db = db

return config
