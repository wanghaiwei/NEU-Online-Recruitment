update post
set is_pinned = true
where group_id = $1
  and id = $2
returning id;