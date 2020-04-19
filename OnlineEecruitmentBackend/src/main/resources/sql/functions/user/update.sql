create or replace function UserInfoUpdate(username varchar, user_nickname varchar, user_gender varchar,
                                          user_description varchar, user_avatar varchar, user_expected_career_id int)
    returns integer
as
$UserInfoUpdate$
    -- 返回    0  更新成功
    -- 返回    -1 更新信息表失败
DECLARE
    RESULT int;
    UserId int;

BEGIN
    BEGIN
        UserId = (select id from "user" where phone = username);
    END;

    BEGIN
        INSERT INTO user_info(user_id, nickname, nikename_last_update, gender, description, avatar,
                              expected_career_id, register_time)
        VALUES (UserId, user_nickname, localtimestamp, user_gender, user_description, user_avatar,
                user_description, localtimestamp)
        ON conflict(user_id) DO UPDATE
            SET nickname             = user_nickname,
                nikename_last_update = localtimestamp,
                gender               = user_gender,
                description          = user_description,
                avatar               = user_avatar,
                expected_career_id   = user_expected_career_id;
    EXCEPTION
        when others then
            RESULT = -1;
    END;
    return RESULT;
END;
$UserInfoUpdate$ LANGUAGE plpgsql;