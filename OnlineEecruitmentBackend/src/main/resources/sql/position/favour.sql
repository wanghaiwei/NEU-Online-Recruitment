INSERT into user_position_favorite (user_id, position_info_id)
VALUES ($1, $2)
ON CONFLICT (position_info_id,user_id) DO nothing
RETURNING id;