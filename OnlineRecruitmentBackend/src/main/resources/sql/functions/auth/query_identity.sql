create or replace function QueryIdentity(user_phone varchar)
    returns setof identities
as
    -- 返回   查询结果
$QueryIdentity$
DECLARE
    RESULT        identities;

BEGIN
    BEGIN
        select "user".identity, authentication_info.identity
        into RESULT
        from "user"
                 left join authentication_info on "user".id = authentication_info.user_id
        where phone = user_phone;
    END;

    return NEXT RESULT;
END;
$QueryIdentity$ LANGUAGE plpgsql;