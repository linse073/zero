.simple_user {
    name 0 : string
    id 1 : integer
    prof 2 : integer
    level 3 : integer
    fight_point 4 : integer
}

.account_info {
    user 0 : *simple_user
}

.position {
    x 0 : integer
    y 1 : integer
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
    arena_rank 9 : integer
    arena_count 10 : integer
    charge_arena 11 : integer
    fight_point 12 : integer
    cur_pos 13 : position
    des_pos 14 : position
    sign_in 15 : *boolean
    sign_in_day 16 : integer
}

.other_info {
    name 0 : string
    id 1 : integer
    prof 2 : integer
    level 3 : integer
    cur_pos 4 : position
    des_pos 5 : position
    fight 6 : boolean
}

.other_all {
    other 0 : *other_info
}

.update_other {
    id 0 : integer
    level 1 : integer
    des_pos 2 : position
    fight 3 : boolean
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
    intensify 6 : integer
    rand_prop 7 : *rand_prop
    status 8 : integer
    status_time 9 : integer
    price 10 : integer
}

.card_info {
    .skill_info {
        id 0 : integer
        level 1 : integer
        exp 2 : integer
        status 3 : integer
    }

    id 0 : integer
    cardid 1 : integer
    level 2 : integer
    pos 3 : *integer
    passive_skill 4 : *skill_info
}

.stage_info {
    id 0 : integer
    count 1 : integer
    time 2 : integer
    hit_score 3 : integer
    trap_score 4 : integer
    hp_score 5 : integer
    star 6 : integer
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
    .simple_card {
        id 0 : integer
        cardid 1 : integer
        level 2 : integer
    }

    id 0 : integer
    name 1 : string
    prof 2 : integer
    level 3 : integer
    fight_point 4 : integer
    card 5 : *simple_card
    rank 6 : integer
}

.user_all {
    user 0 : user_info
    item 1 : *item_info
    stage 2 : *stage_info
    task 3 : *task_info
    card 4 : *card_info
    friend 5 : *friend_info
}

.info_all {
    user 0 : user_all
    start_time 1 : integer
    stage_id 2 : integer
    rand_seed 3 : integer
}

.update_user {
    msgid 0 : integer
    update 1 : user_all
    sign_in 2 : integer
    rand_seed 3 : integer
    compound_crit 4 : integer
}

.update_day {
    task 0 : *integer
    update_sign_in 1 : boolean
}

.heart_beat {
    time 0 : integer
}

.heart_beat_response {
    time 0 : integer
    server_time 1 : integer
}

.error_code {
    msgid 0 : integer
    code 1 : integer
}

.create_user {
    name 0 : string
    prof 1 : integer
}

.enter_game {
    id 0 : integer
}

.use_item {
    id 0 : integer
    pos 1 : integer
}

.compound_item {
    itemid 0 : integer
    num 1 : integer
}

.upgrade_item {
    id 0 : integer
}

.improve_item {
    id 0 : integer
}

.decompose_item {
    id 0 : integer
}

.intensify_item {
    id 0 : integer
}

.inlay_item {
    id 0 : integer
}

.uninlay_item {
    id 0 : integer
}

.submit_task {
    id 0 : integer
    condition 1 : integer
}

.call_card {
    cardid 0 : integer
}

.upgrade_card {
    id 0 : integer
}

.promote_card {
    id 0 : integer
}

.use_card {
    id 0 : integer
    pos_type 1 : integer
    pos 2 : integer
}

.begin_stage {
    id 0 : integer
}

.end_stage {
    id 0 : integer
    rand_seed 1 : integer
    time 2 : integer
    hit_score 3 : integer
    trap_score 4 : integer
    hp_score 5 : integer
    total_gold 6 : integer
    pick_gold 7 : integer
    total_box 8 : integer
    pick_box 9 : *integer
    sign 10 : string
}

.open_chest {
    pick_chest 0 : integer
}

.stage_seed {
    id 0 : integer
    rand_seed 1 : integer
    target 2 : user_all
}

.move {
    des_pos 0 : position
}

.logout {
    id 0 : integer
}

.add_item {
    itemid 0 : integer
    num 1 : integer
}

.add_exp {
    exp 0 : integer
}

.add_level {
    level 0 : integer
}

.add_money {
    money 0 : integer
}

.add_rmb {
    rmb 0 : integer
}

.upgrade_passive {
    id 0 : integer
    skillid 1 : integer
    rmb 2 : boolean
}

.query_rank {
    rank_type 0 : integer
}

.rank_list {
    rank_type 0 : integer
    rank 1 : integer
    list 2 : *rank_info
}

.begin_challenge {
    rank_type 0 : integer
    id 1 : integer
}

.sign_in {
    patch 0 : boolean
}
