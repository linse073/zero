.simple_user {
    name 0 : string
    id 1 : integer
    prof 2 : integer
    level 3 : integer
}

.account_info {
    user 0 : *simple_user
}

.user_info {
    name 0 : string
    id 1 : integer
    prof 2 : integer
    level 3 : integer
    exp 4 : integer
    charge 5 : integer
    vip 6 : integer
    rmb 7 : integer
    money 8 : integer
    rank 9 : integer
    arena_count 10 : integer
    charge_arena 11 : integer
    fight_point 12 : integer
}

.item_info {
    .rand_prop {
        type 0 : integer
        value 1 : integer
    }

    id 0 : integer
    itemid 1 : integer
    owner 2 : integer
    num 3 : integer
    pos 4 : integer
    host 5 : integer
    upgrade 6 : integer
    rand_prop 7 : *rand_prop
    status 8 : integer
    status_time 9 : integer
    price 10 : integer
}

.card_info {
    id 0 : integer
    exp 1 : integer
    star_exp 2 : integer
    pos 3 : integer
}

.stage_info {
    id 0 : integer
    star 1 : integer
    day_count 2 : integer
    total_count 3 : integer
    best_time 4 : integer
    best_hit 5 : integer
}

.task_info {
    id 0 : integer
    status 1 : integer
    count 2 : integer
}

.friend_info {
    id 0 : integer
    name 1 : string
    prof 2 : integer
    level 3 : integer
    fight_point 4 : integer
}

.rank_info {
    id 0 : integer
    name 1 : string
    prof 2 : integer
    level 3 : integer
    fight_point 4 : integer
    rank 5 : integer
}

.user_all {
    user 0 : user_info
    item 1 : *item_info
    stage 2 : *stage_info
    task 3 : *task_info
    card 4 : *card_info
    friend 5 : *friend_info
}

.update_day {
    task 0 : *integer
}

.heart_beat {
    time 0 : integer
}

.heart_beat_response {
    time 0 : integer
    server_time 1 : integer
}

.error_code {
    id 0 : integer
    code 1 : integer
}

.create_user {
    name 0 : string
    prof 1 : integer
}

.enter_game {
    id 0 : integer
}