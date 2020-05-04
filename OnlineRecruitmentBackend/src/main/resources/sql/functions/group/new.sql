create or replace function PostNewGroup(group_name varchar, group_avatar varchar, group_description varchar,
                                        group_category int, group_user_id int)
    returns integer
as
$PostNewPosition$
    -- 返回  ID 插入的ID
    -- 返回  -2 额度已用完
    -- 返回  -3 创建条件不足
DECLARE
    CREDIT   int;
    COUNT    int;
    RESULT   int;
    GROUP_ID int;

BEGIN
    BEGIN
        CREDIT = (select credit from user_credit where user_id = group_user_id);
        IF CREDIT < 10 THEN
            RESULT = -3;
            RETURN RESULT;
        end if;
    END;

    BEGIN
        COUNT = (select distinct COUNT(id)
                 from post
                 where user_id = group_user_id
                   AND length(content) >= 200
                   AND (select distinct COUNT(group_id)
                        from post
                        where user_id = group_user_id
                          AND length(content) >= 200) >= 3);
        IF CREDIT < 15 THEN
            RESULT = -3;
            RETURN RESULT;
        end if;
    END;

    BEGIN
        COUNT = (select COUNT(*) from "group_user_map" where user_id = group_user_id);
        IF CREDIT >= 2 THEN
            RESULT = -2;
            RETURN RESULT;
        end if;
    END;

    BEGIN
        insert into "group"(name, logo, description, group_category_id, logo_last_update)
        values (group_name, group_avatar, group_description, group_category, localtimestamp)
        on conflict (name) do nothing
        returning id into GROUP_ID;
        if GROUP_ID is not null then
            insert into group_user_map(user_id, group_id, state, user_join_time)
            VALUES (group_user_id, GROUP_ID, 0, localtimestamp);
            UPDATE "user"
            set identity = 100
            where phone = group_user_id;
            RESULT = 0;
        else
            RESULT = -1;
        end if;
    EXCEPTION
        when others then
            RESULT = -1;
    END;

    return RESULT;
END;
$PostNewPosition$ LANGUAGE plpgsql;