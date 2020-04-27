update user_credit
set credit = 0
and banned_begin_time = localtimestamp
where user_id = $1
returning id;