create or replace function GroupAdminUserWarn(warn_user_id int)
    returns integer
as
$GroupAdminUserWarn$
    -- 返回  0   执行成功
    -- 返回  -1  执行失败
DECLARE
    RESULT int;
    CREDIT int;

BEGIN
    BEGIN
        CREDIT = (select credit from user_credit where user_id = warn_user_id) - 1;
        if CREDIT = 0 Then
            update user_credit
            set banned_begin_time = localtimestamp,
                credit            = credit
            where user_id = warn_user_id;
        else
            update user_credit
            set credit = credit
            where user_id = warn_user_id;
        end if;
        RESULT = 0;
    EXCEPTION
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;

    return RESULT;
END;
$GroupAdminUserWarn$ LANGUAGE plpgsql;