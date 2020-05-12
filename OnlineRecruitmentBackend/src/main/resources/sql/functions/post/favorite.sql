create or replace function FavoritePost(post_favorite_id int, post_user_id int)
    returns INTEGER
as
$LikePost$
    -- 返回  ID 插入的ID
    -- 返回  -1 数据库异常
DECLARE
    RESULT int;

BEGIN
    BEGIN
        Insert Into user_post_favorite(post_id, user_id)
        values (post_favorite_id, post_user_id)
        returning id into RESULT;
        UPDATE post
        SET favorite_number = (select like_number from post where id = post_favorite_id) + 1
        where id = post_favorite_id;
        return RESULT;
    Exception
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;
END;
$LikePost$ LANGUAGE plpgsql;