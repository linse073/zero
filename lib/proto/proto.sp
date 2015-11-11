.error_code {
    code 0 : integer
}

.account_info {
    .simple_user {
        name 0 : string
        id 1 : integer
        prof 2 : integer
        level 3 : integer
    }
    user 0 : *simple_user
}
