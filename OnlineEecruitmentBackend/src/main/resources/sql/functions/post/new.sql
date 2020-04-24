create or replace function NewPost(post_group_id int, post_user_id int, post_content varchar)
    returns INTEGER
as
$FetchAllPost$
    -- 返回  ID 插入的ID
    -- 返回  -1 添加失败
DECLARE
    RESULT int;

BEGIN
    BEGIN
        Insert Into post(content, group_id, user_id, like_number, comment_number, favorite_number, is_pinned, timestamp)
        values (post_content, post_group_id, post_user_id, 0, 0, 0, false, localtimestamp)
        returning id into RESULT;
        return RESULT;
    Exception
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;
END;
$FetchAllPost$ LANGUAGE plpgsql;