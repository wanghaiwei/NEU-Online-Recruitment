create or replace function UpdatePassword(user_phone varchar, user_password_old varchar, user_password_new varchar)
    returns integer
as
    -- 返回    0  更新成功
    -- 返回    -1 用户名或密码错误
$UpdatePassword$
DECLARE
    RESULT int;
    Count  int;

BEGIN
    Count = (select count(*) from "user" where "user".phone = user_phone and user_password_old = password);
    if Count = 1 then
        UPDATE "user"
        SET password = user_password_new
        where phone = user_phone;
        RESULT = 0;
    else
        RESULT = -1;
    end if;
    return RESULT;
END;
$UpdatePassword$ LANGUAGE plpgsql;