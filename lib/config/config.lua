
local config = {}

config.server = {
    {
        serverid = 1,
        servername = "server01",
    },
}

config.gate = {
    ip = "118.89.196.138",
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

config.log = {
    host = "127.0.0.1",
    name = {
        "ioscharge",
        "register",
    }
}

return config
