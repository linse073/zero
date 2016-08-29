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
    exchange_count 17 : integer
    online_award_time 18 : integer
    online_award_count 19 : integer
    arena_cd 20 : integer
    refresh_arena_cd  21 : integer
    match_count 22 : integer
    match_cd 23 : integer
    refresh_match_cd 24 : integer
    match_win 25 : integer
    offline_exp_time 26 : integer
    offline_exp_count 27 : integer
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

.rand_prop {
    type 0 : integer
    value 1 : integer
}

.item_info {
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
    status 5 : integer
    online 6 : boolean
}

.mail_info {
    id 0 : integer
    type 1 : integer
    time 2 : integer
    status 3 : integer
    title 4 : string
    content 5 : string
    item_info 6 : *item_info
}

.rank_info {
    .simple_card {
        id 0 : integer
        cardid 1 : integer
        level 2 : integer
        pos 3 : integer
    }

    id 0 : integer
    name 1 : string
    prof 2 : integer
    level 3 : integer
    fight_point 4 : integer
    card 5 : *simple_card
    rank 6 : integer
    win 7 : boolean
}

.explore_info {
    area 0 : integer
    start_time 1 : integer
    status 2 : integer
    reason 3 : integer
    time 4 : integer
    tinfo 5 : rank_info
    ack 6 : integer
    tack 7 : integer
}

.user_all {
    .mall_count {
        id 0 : integer
        count 1 : integer
    }

    user 0 : user_info
    item 1 : *item_info
    stage 2 : *stage_info
    task 3 : *task_info
    card 4 : *card_info
    friend 5 : *friend_info
    mail 6 : *mail_info
    explore 7 : explore_info
    stage_award 8 : *integer
    trade_watch 9 : *integer
    mall_random 10 : *integer
    mall_count 11 : *mall_count
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
    add_watch 5 : boolean
    buy_item 6 : buy_item
    rank_list 7 : rank_list
}

.update_day {
    task 0 : *integer
    update_sign_in 1 : boolean
    arena_award 2 : mail_info
    mall_random 3 : *integer
    mall_week 4 : boolean
    mall_time 5 : boolean
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
    pos 1 : integer
    stone 2 : integer
}

.uninlay_item {
    id 0 : integer
    pos 1 : integer
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
    monster 10 : integer
    elite_monster 11 : integer
    boss 12 : integer
    sign 13 : string
}

.open_chest {
    pick_chest 0 : integer
}

.stage_seed {
    id 0 : integer
    rand_seed 1 : integer
    target 2 : user_all
    rank_type 3 : integer
    cd 4 : integer
    count 5 : integer
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

.set_task {
    id 0 : integer
}

.add_mail {
    type 0 : integer
    title 1 : string
    content 2 : string
    item_info 3 : *item_info
}

.broadcast_mail {
    type 0 : integer
    title 1 : string
    content 2 : string
    item_info 3 : *item_info
}

.test_charge {
    num 0 : integer
}

.reset_online_award {
    time 0 : integer
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

.explore {
    area 0 : integer
}

.get_stage_award {
    area 0 : integer
}

.chat_info {
    .chat_item {
        itemid 0 : integer
        intensify 1 : integer
        rand_prop 2 : *rand_prop
    }

    id 0 : integer
    name 1 : string
    level 2 : integer
    prof 3 : integer
    fight_point 4 : integer
    type 5 : integer
    target 6 : integer
    text 7 : string
    item 8 : *chat_item
}

.read_mail {
    id 0 : integer
}

.del_mail {
    id 0 : integer
}

.request_friend {
    id 0 : integer
}

.confirm_friend {
    id 0 : integer
    accept 1 : boolean
}

.blacklist {
    id 0 : integer
}

.del_friend {
    id 0 : integer
}

.query_friend {
    name 0 : string
}

.query_friend_info {
    info 0 : *simple_user
}

.get_role_info {
    id 0 : integer
}

.role_info {
    info 0 : user_all
}

.query_sell {
    id 0 : integer
}

.query_sell_info {
    id 0 : integer
    info 1 : *item_info
}

.sell_item {
    id 0 : integer
    itemid 1 : integer
    num 2 : integer
    price 3 : integer
}

.back_item {
    id 0 : integer
    itemid 1 : integer
    price 2 : integer
}

.buy_item {
    id 0 : integer
    itemid 1 : integer
    num 2 : integer
    price 3 : integer
}

.add_watch {
    id 0 : integer
}

.del_watch {
    id 0 : integer
}

.end_challenge {
    rank_type 0 : integer
    id 1 : integer
    time 2 : integer
    sign 3 : string
}

.refresh_arena {
    rank_type 0 : integer
}

.mall_item {
    id 0 : integer
}

.slave_rank {
    type 0 : integer
}

.simple_rank_info {
    id 0 : integer
    name 1 : string
    prof 2 : integer
    level 3 : integer
    fight_point 4 : integer
    rank 5 : integer
    value 6 : integer
}

.slave_rank_list {
    type 0 : integer
    rank 1 : integer
    value 2 : integer
    list 3 : *simple_rank_info
}
