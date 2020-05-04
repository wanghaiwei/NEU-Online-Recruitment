create or replace function DeletePost(post_id int, post_user_id int)
    returns INTEGER
as
$DeletePost$
    -- 返回  ID 插入的ID
    -- 返回  -1 添加失败
DECLARE
    RESULT         int;
    STORED_USER_ID int;

BEGIN
    BEGIN
        STORED_USER_ID = (select user_id from post where id = post_id);
        if STORED_USER_ID != post_user_id THEN
            RESULT = -1;
        else
            Delete from post where user_id = post_user_id AND id = post_id;
            RESULT = 0;
        end if;
        return RESULT;
    Exception
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;
END;
$DeletePost$ LANGUAGE plpgsql;