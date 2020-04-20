create or replace function PostNewPosition(position_name varchar, position_company varchar,
                                           position_description varchar, position_post_mail varchar,
                                           position_grade varchar, position_location varchar,
                                           position_position_category_id int, position_post_user_id int)
    returns integer
as
$PostNewPosition$
    -- 返回  ID 插入的ID
    -- 返回  -1  用户未认证或额度已用完
DECLARE
    QUOTA  int;
    RESULT int;

BEGIN
    BEGIN
        QUOTA = (SELECT quota from user_quota where uid = position_post_user_id);
        IF QUOTA <= 0 THEN
            RESULT = -1;
            return RESULT;
        else
            QUOTA = QUOTA - 1;
            UPDATE user_quota set quota = QUOTA where uid = position_post_user_id;
        end if;
    END;

    BEGIN
        INSERT INTO position_info(name, company, description, post_mail, grade, location, position_category_id,
                                  post_user_id)
        values (position_name, position_company, position_description, position_post_mail, position_grade,
                position_location, position_position_category_id, position_post_user_id);
        RESULT = 0;
    EXCEPTION
        when others then
            QUOTA = QUOTA + 1;
            UPDATE user_quota set quota = QUOTA where uid = position_post_user_id;
            RESULT = -1;
    END;
    return RESULT;
END;
$PostNewPosition$ LANGUAGE plpgsql;