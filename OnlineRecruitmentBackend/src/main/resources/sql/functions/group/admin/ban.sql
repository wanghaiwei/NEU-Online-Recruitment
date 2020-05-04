create or replace function GroupAdminUserBan(ban_group_id int, ban_user_id int)
    returns integer
as
$GroupAdminUserBan$
    -- 返回  0   执行成功
    -- 返回  -1  执行失败
DECLARE
    RESULT int;

BEGIN
    BEGIN
        Insert Into group_banned(user_id, group_id)
        values (ban_group_id, ban_user_id)
        on conflict (user_id,group_id) do nothing
        returning id into RESULT;
        RESULT = 0;
    EXCEPTION
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;

    return RESULT;
END;
$GroupAdminUserBan$ LANGUAGE plpgsql;