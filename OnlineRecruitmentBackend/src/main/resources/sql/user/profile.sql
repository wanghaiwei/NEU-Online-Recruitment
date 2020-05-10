select id, nickname, avatar, description
from "user_info"
where user_id = $1;