create or replace function SubmitAuthentication(user_phone varchar, user_identity int, user_company varchar,
                                                user_position varchar, user_mail varchar, user_mail_can_verify bool,
                                                user_company_serial varchar)
    returns integer
as
    -- 返回    0  更新成功
    -- 返回    -1 数据库更新失败
$SubmitAuthentication$
DECLARE
    RESULT int;
    Count  int;
    UserId int;

BEGIN
    BEGIN
        UserId = (select id from "user" where phone = user_phone);
    Exception
        when others then
            RESULT = -1;
    END;

    Begin
        Count = (select count(*) from authentication_info where user_id = UserId);
        if Count = 1 then
            Update authentication_info
            set begin_time            = localtimestamp,
                end_time              = localtimestamp + interval '90 days',
                identity              = user_identity,
                company               = user_company,
                company_serial        = user_company_serial,
                position              = user_position,
                mail                  = user_mail,
                mail_can_verify       = user_mail_can_verify,
                authentication_status = 0
            where user_id = UserId;
            RESULT = 0;
        else
            INSERT INTO authentication_info(user_id, identity, begin_time, end_time, company, position, mail,
                                            company_serial, authentication_status, mail_can_verify)
            values (UserId, user_identity, localtimestamp, localtimestamp + interval '90 days', user_company,
                    user_position,
                    user_mail, user_company_serial, 0, user_mail_can_verify);
            RESULT = 0;
        end if;
    Exception
        when others then
            RESULT = -1;
    END;

    return RESULT;
END ;
$SubmitAuthentication$ LANGUAGE plpgsql;