create or replace function LikePost(post_like_id int, post_user_id int)
    returns INTEGER
as
$LikePost$
    -- 返回  ID 插入的ID
    -- 返回  -1 数据库异常
DECLARE
    RESULT int;

BEGIN
    BEGIN
        Insert Into post_like(post_id, user_id)
        values (post_like_id, post_user_id)
        returning id into RESULT;
        UPDATE post
        SET like_number = (select like_number from post where id = post_like_id) + 1
        where id = post_like_id;
        return RESULT;
    Exception
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;
END;
$LikePost$ LANGUAGE plpgsql;