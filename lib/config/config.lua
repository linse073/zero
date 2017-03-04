
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
    maxclient = 65535,
    servername = "gate01",
}

config.db = {
    host = "127.0.0.1",
    port = 6379,
    base = 0,
    name = {
        "accountdb",
        "accountnamedb",
        "userdb",
        "namedb",
        "tradedb",
        "rankdb",
        "rankinfodb",
        "exploredb",
        "offlinedb",
        "statusdb",
        "guilddb",
    }
}

return config
