update authentication_info
set authentication_status = $2
where id = $1
returning user_id;