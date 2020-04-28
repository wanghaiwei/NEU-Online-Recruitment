create or replace function SearchPosition(content varchar, query_location varchar, position_category_ids int[],
                                           grade int[])
    returns SETOF position_info
as
$SearchPosition$
    -- 返回 position_info
DECLARE

BEGIN
    BEGIN
        if -1 = any (position_category_ids) Then
            RETURN Query select *
                         from position_info
                         where location like query_location
                           and (name like content or description like content);
        else
            RETURN Query select *
                         from position_info
                         where location like query_location
                           and (name like content or description like content)
                           and position_category_id = any (position_category_ids);
        end if;
    END;
END ;
$SearchPosition$ LANGUAGE plpgsql;