insert into position_user_recommend(user_id, recommend)
values ($1, $2)
on conflict(user_id) do update
    set recommend = $2
where user_id = $1;