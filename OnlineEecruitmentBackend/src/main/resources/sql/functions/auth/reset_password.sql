create or replace function ResetPassword(user_phone varchar, user_password varchar)
    returns integer
as
    -- 返回    0  更新成功
    -- 返回    -1 更新信息表失败
$ResetPassword$
DECLARE
    RESULT int;
    Count  int;

BEGIN
    Count = (select count(*) from "user" where "user".phone = user_phone);
    if Count == 1 then
        UPDATE "user"
        SET password = user_password
        where phone = user_phone;
    else
        RESULT = -1;
    end if;
    return RESULT;
END;
$ResetPassword$ LANGUAGE plpgsql;