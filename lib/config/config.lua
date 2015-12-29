
local config = {}

config.server = {
    {
        serverid = 1,
        servername = "server01",
    },
}

config.gate = {
    ip = "192.168.1.202",
    port = 8888,
    maxclient = 64,
    servername = "gate01",
}

local db_base = 0
config.db = {
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

return config
