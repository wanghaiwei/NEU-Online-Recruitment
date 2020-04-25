create or replace function CommentPost(comment_post_id int, comment_user_id int, comment_content varchar)
    returns INTEGER
as
$CommentPost$
    -- 返回  ID 插入的ID
    -- 返回  -1 添加失败
DECLARE
    RESULT int;

BEGIN
    BEGIN
        Insert Into post_comment(post_id, content, user_id, timestamp)
        values (comment_post_id,comment_user_id,comment_content, localtimestamp)
        returning id into RESULT;
        UPDATE post
        SET comment_number = (select comment_number from post where id = comment_post_id) + 1
        where id = comment_post_id;
        return RESULT;
    Exception
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;
END;
$CommentPost$ LANGUAGE plpgsql;