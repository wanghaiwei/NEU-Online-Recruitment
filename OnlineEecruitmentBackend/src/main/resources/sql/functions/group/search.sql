create or replace function PostSearchGroup(group_desc varchar, group_category int[])
    returns SETOF "group"
as
$PostSearchGroup$
    -- 返回 group
DECLARE

BEGIN
    BEGIN
        if -1 = any (group_category) Then
            RETURN Query select *
                         from "group"
                         where name like group_desc
                            or description like group_desc;
        else
            RETURN Query select *
                         from "group"
                         where id = any (group_category)
                           and (name like group_desc
                             or description like group_desc);
        end if;
    END;
END ;
$PostSearchGroup$ LANGUAGE plpgsql;