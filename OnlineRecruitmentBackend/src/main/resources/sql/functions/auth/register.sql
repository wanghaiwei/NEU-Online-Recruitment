create or replace function Register(user_phone varchar, user_password varchar)
    returns integer
as
    -- 返回    0  更新成功
    -- 返回    -1 更新信息表失败
$Register$
DECLARE
    RESULT int;
    Count  int;
    UserID int;

BEGIN
    Count = (select count(*)
             from "user"
             where "user".phone = user_phone);
    if Count = 1 then
        RESULT = -1;
    else
        insert into "user" (password, phone) values (user_password, user_phone) returning id into UserID;
        insert into user_credit (user_id, credit) values (UserID, 10);
        RESULT = UserID;
    end if;
    return RESULT;
END;
$Register$ LANGUAGE plpgsql;