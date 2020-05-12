create or replace function UpdatePost(post_id int, post_user_id int, post_content varchar)
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
        IsInGroup = (SELECT count(*) from post where user_id = post_user_id and id = post_id);
        IF IsInGroup = 0 Then
            RESULT = -1;
            RETURN RESULT;
        end if;
    end;

    BEGIN
        UPDATE post
        set content = post_content
        where id = post_id
          and user_id = post_user_id
        returning id into RESULT;
        return RESULT;
    Exception
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;
END;
$FetchAllPost$ LANGUAGE plpgsql;