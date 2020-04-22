create or replace function PostNewPosition(position_post_user_id int, position_id int)
    returns integer
as
$PostNewPosition$
    -- 返回  ID 插入的ID
    -- 返回  -1 用户不是该记录拥有者或删除失败
DECLARE
    QUOTA    int;
    IDENTITY int;
    CNT      int;
    RESULT   int;

BEGIN
    BEGIN
        CNT = (SELECT count(id) from position_info where post_user_id = position_post_user_id and id = position_id);
        if CNT = 0 then
            RESULT = -1;
            RETURN RESULT;
        end if;
    END;

    BEGIN
        Delete from position_info where post_user_id = position_post_user_id and id = position_id;
    END;

    BEGIN
        QUOTA = (select quota from user_quota where uid = position_post_user_id);
        IDENTITY = (select identity from "authentication_info" where user_id = position_post_user_id);
        if IDENTITY = 1 Then
            if QUOTA + 1 > 5 Then
                QUOTA = 5;
            else
                QUOTA = QUOTA + 1;
            end if;
        end if;
        if IDENTITY = 0 Then
            if QUOTA + 1 > 1 Then
                QUOTA = 1;
            else
                QUOTA = QUOTA + 1;
            end if;
        end if;
        update "user_quota" set quota = QUOTA where uid = position_post_user_id;
        RESULT = 0;
    END;

    return RESULT;
END;
$PostNewPosition$ LANGUAGE plpgsql;