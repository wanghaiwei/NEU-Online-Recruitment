select state
from group_user_map
where group_id = $1
  and user_id = $2;