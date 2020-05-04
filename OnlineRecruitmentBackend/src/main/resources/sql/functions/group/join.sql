create or replace function PostJoinGroup(group_id int, group_user_id int)
    returns integer
as
$PostJoinGroup$
    -- 返回  ID 插入的ID
DECLARE
    RESULT int;

BEGIN
    BEGIN
        insert into group_user_map(user_id, group_id, state, user_join_time)
        VALUES (group_user_id, group_id, 1, localtimestamp)
        on conflict do nothing;
        RESULT = 0;
    EXCEPTION
        when others then
            RESULT = -1;
    END;

    return RESULT;
END;
$PostJoinGroup$ LANGUAGE plpgsql;