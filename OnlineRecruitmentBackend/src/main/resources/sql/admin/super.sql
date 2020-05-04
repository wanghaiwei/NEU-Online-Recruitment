update "user"
set identity = 0
where id = $1
returning id;