update post
set is_pinned = true
where id = $2
returning id;