insert into position_recommend_data(position_id, next_id, hit_count)
values ($1, $2, $3)
on conflict(position_id, next_id) do update
    set hit_count = $3
where position_recommend_data.position_id = $1
  and position_recommend_data.next_id = $2;