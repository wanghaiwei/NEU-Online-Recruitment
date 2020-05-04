create or replace function NewPost(post_group_id int, post_user_id int, post_content varchar)
    returns INTEGER
as
$FetchAllPost$
    -- 返回  ID 插入的ID
    -- 返回  -1 添加失败
DECLARE
    IsInGroup int;
    RESULT    int;

BEGIN
    BEGIN
        IsInGroup = (SELECT count(*) from group_user_map where user_id = post_user_id and group_id = post_group_id);
        IF IsInGroup = 1 Then
            RESULT = -1;
            RETURN RESULT;
        end if;
    end;

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