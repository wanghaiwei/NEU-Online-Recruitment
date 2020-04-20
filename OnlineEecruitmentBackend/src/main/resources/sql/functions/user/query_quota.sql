create or replace function QueryQuota(username varchar)
    returns integer
as
$UserInfoUpdate$
    -- 返回  int 额度
    -- 返回  -1  用户未认证或额度已用完
DECLARE
    RESULT int;

BEGIN
    BEGIN
        select quota
        into RESULT
        from user_quota
                 left join "user" on user_quota.uid = "user".id
        where phone = username;
        if RESULT IS NULL then
            RESULT = -1;
        end if;
    EXCEPTION
        when others then
            RESULT = -1;
    END;
    return RESULT;
END;
$UserInfoUpdate$ LANGUAGE plpgsql;