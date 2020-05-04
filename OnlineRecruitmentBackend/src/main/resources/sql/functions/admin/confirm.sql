create or replace function ConfirmAuth(confirm_auth_id int, status int)
    returns integer
as
    -- 返回   查询结果
$ConfirmAuth$
DECLARE
    IDENTITY int;
    RESULT   int;
    CNT      int;
    QUOTA    int;
BEGIN
    BEGIN
        update authentication_info
        set authentication_status = status
        where id = confirm_auth_id;
        CNT = (select count(*) from position_info where post_user_id = confirm_auth_id);
        IDENTITY = (select identity from "authentication_info" where user_id = confirm_auth_id);
        if IDENTITY = 1 Then
            if CNT > 5 Then
                QUOTA = 0;
            else
                QUOTA = 5 - CNT;
            end if;
        end if;
        if IDENTITY = 0 Then
            if CNT > 1 Then
                QUOTA = 0;
            else
                QUOTA = 1 - CNT;
            end if;
        end if;
        Insert Into user_quota(uid, quota)
        values (confirm_auth_id, QUOTA)
        on conflict(uid) do update
            set quota = QUOTA
        where uid = confirm_auth_id;
        RESULT = 1;
    END;

    return RESULT;
END;
$ConfirmAuth$ LANGUAGE plpgsql;